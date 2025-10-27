# JOIN查询跨类型比较修复说明

## 问题描述

当JOIN条件中包含不同数据类型的比较（如字符串与整数）时，查询返回FAILURE而不是正确的结果。

示例查询：
```sql
INSERT INTO join_table_1 VALUES (4, '16a');
SELECT * FROM join_table_1 INNER JOIN join_table_2 
ON join_table_1.name<join_table_2.age AND join_table_1.id=join_table_2.id;
```

其中 `name` 是 CHARS 类型，`age` 是 INTS 类型。

**预期**：返回 SUCCESS，0行数据（因为 '16a' → 16，16 < 5 = false）  
**实际**：返回 FAILURE

## 根本原因

问题出在**逻辑计划生成阶段**，而不是执行阶段。

在 `src/observer/sql/optimizer/logical_plan_generator.cpp` 第198-233行，系统会检查类型转换成本。如果两个类型之间的转换成本都是 `INT32_MAX`（表示不支持转换），就会返回 `RC::UNSUPPORTED` 错误：

```cpp
} else {
    rc = RC::UNSUPPORTED;
    LOG_WARN("unsupported cast from %s to %s", ...);
    return rc;  // 直接返回错误，查询失败
}
```

原来的类型转换成本：
- `CharType::cast_cost(INTS)` = `INT32_MAX` (不支持)
- `CharType::cast_cost(FLOATS)` = `INT32_MAX` (不支持)
- `IntegerType::cast_cost(CHARS)` = `INT32_MAX` (不支持)
- `FloatType::cast_cost(CHARS)` = `INT32_MAX` (不支持)

因此，在生成逻辑计划时就直接失败了，根本没有执行到后续的比较逻辑。

## 修复方案

### 1. 添加类型转换成本支持

修改了各类型的 `cast_cost` 方法，允许字符串与数值类型之间相互转换：

**CharType** (`src/observer/common/type/char_type.cpp`):
```cpp
int CharType::cast_cost(AttrType type)
{
  if (type == AttrType::CHARS) return 0;
  if (type == AttrType::DATES) return 1;
  if (type == AttrType::INTS || type == AttrType::FLOATS) {
    return 2;  // 支持转换到数值类型，成本为 2
  }
  return INT32_MAX;
}
```

**IntegerType** (`src/observer/common/type/integer_type.h`):
```cpp
int cast_cost(const AttrType type) override
{
  if (type == AttrType::INTS) return 0;
  else if (type == AttrType::FLOATS) return 1;
  else if (type == AttrType::CHARS) return 2;  // 支持转换到字符串
  return INT32_MAX;
}
```

**FloatType** (`src/observer/common/type/float_type.h`):
```cpp
int cast_cost(const AttrType type) override
{
  if (type == AttrType::FLOATS) return 0;
  else if (type == AttrType::INTS) return 1;
  else if (type == AttrType::CHARS) return 2;  // 支持转换到字符串
  return INT32_MAX;
}
```

### 2. 实现实际的类型转换函数

**CharType::cast_to** - 支持转换到INTS和FLOATS：
```cpp
case AttrType::INTS: {
  result.set_type(AttrType::INTS);
  return DataType::type_instance(AttrType::INTS)->set_value_from_str(result, val.get_string());
}
case AttrType::FLOATS: {
  result.set_type(AttrType::FLOATS);
  return DataType::type_instance(AttrType::FLOATS)->set_value_from_str(result, val.get_string());
}
```

**IntegerType::cast_to** - 支持转换到CHARS：
```cpp
case AttrType::CHARS: {
  string str_value = std::to_string(val.get_int());
  result.set_string(str_value.c_str());
  return RC::SUCCESS;
}
```

**FloatType::cast_to** - 支持转换到CHARS：
```cpp
case AttrType::CHARS: {
  string str_value;
  RC rc = to_string(val, str_value);
  if (rc == RC::SUCCESS) {
    result.set_string(str_value.c_str());
  }
  return rc;
}
```

### 3. 支持向量化比较的跨类型处理

在 `src/observer/sql/expr/expression.cpp` 的 `ComparisonExpr::eval` 方法中，当列类型不同时使用逐行比较：

```cpp
// 如果两列类型不同，使用逐行比较（支持跨类型比较）
if (left_column.attr_type() != right_column.attr_type()) {
    for (int i = 0; i < rows; ++i) {
      Value left_val = left_column.get_value(i);
      Value right_val = right_column.get_value(i);
      bool result = false;
      rc = compare_value(left_val, right_val, result);
      if (rc != RC::SUCCESS) return rc;
      select[i] &= result ? 1 : 0;
    }
    return rc;
}
```

## 修复文件列表

1. **类型转换成本** - 允许逻辑计划生成：
   - `src/observer/common/type/char_type.cpp` - 字符串类型
   - `src/observer/common/type/integer_type.h` - 整数类型
   - `src/observer/common/type/float_type.h` - 浮点类型

2. **类型转换实现** - 实际转换逻辑：
   - `src/observer/common/type/char_type.cpp` 
   - `src/observer/common/type/integer_type.cpp`
   - `src/observer/common/type/float_type.cpp`

3. **向量化比较** - 执行阶段支持：
   - `src/observer/sql/expr/expression.cpp`

## Docker测试步骤

### 重要：必须重新构建镜像

由于修复了底层类型系统，**必须**重新编译代码：

```bash
# 方法1：重新构建 Docker 镜像（推荐）
cd docker
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 测试查询

```bash
# 进入容器
docker exec -it miniob-container bash
cd /root/miniob

# 创建表
echo "CREATE TABLE join_table_1(id int, name char(20));" | build/bin/obclient
echo "CREATE TABLE join_table_2(id int, age int);" | build/bin/obclient

# 插入测试数据
echo "INSERT INTO join_table_1 VALUES (4, '16a');" | build/bin/obclient
echo "INSERT INTO join_table_2 VALUES (4, 5);" | build/bin/obclient

# 执行JOIN查询 - 应该返回 SUCCESS，0行数据
echo "SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.name<join_table_2.age AND join_table_1.id=join_table_2.id;" | build/bin/obclient
```

### 预期结果

- ✅ 不显示 `FAILURE`
- ✅ 返回 `SUCCESS`
- ✅ 0 行数据（因为 '16a' → 16，16 < 5 = false，条件不满足）

### 其他测试用例

```bash
# 测试用例1：应该返回3行
echo "INSERT INTO join_table_1 VALUES (1, '10a'), (2, '20b'), (3, '3c');" | build/bin/obclient
echo "INSERT INTO join_table_2 VALUES (1, 15), (2, 25), (3, 8);" | build/bin/obclient
echo "SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.name<join_table_2.age AND join_table_1.id=join_table_2.id;" | build/bin/obclient

# 预期：3行（id=1,2,3 都满足条件）
```

## 类型转换规则

修复后支持以下跨类型转换（转换成本为2）：

### CHARS → 数值类型
- `'123'` → `123` (INTS)
- `'3.14'` → `3.14` (FLOATS)
- `'10a'` → `10` (INTS, 部分转换)
- `'abc'` → 转换失败，返回错误

### 数值类型 → CHARS
- `123` → `'123'`
- `3.14` → `'3.14'`

### 转换成本优先级
0. 相同类型：成本 0
1. INTS ↔ FLOATS：成本 1
2. CHARS ↔ DATES：成本 1  
3. **CHARS ↔ INTS/FLOATS：成本 2** (新增)

在比较时，系统会选择成本较低的转换方向。

## Git提交历史

1. `c006da9` - 修复 ComparisonExpr::eval 支持跨类型列比较
2. `3b96f77` - 添加测试文档
3. **`4ee853b`** - **真正的根本修复：添加类型转换支持**

最新代码已推送到：https://github.com/ZJZ-STAR/miniob-2025.git

## 总结

这个问题实际上是**双层问题**：

1. **逻辑计划生成阶段**（根本原因）：缺少类型转换成本和转换实现 → 本次修复
2. **执行阶段**（辅助优化）：向量化比较不支持跨类型 → 之前已修复

只有修复了第1个问题，查询才能通过逻辑计划生成阶段，进入执行阶段。
