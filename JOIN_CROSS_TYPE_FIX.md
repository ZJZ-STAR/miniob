# JOIN查询跨类型比较修复说明

## 问题描述

当JOIN条件中包含不同数据类型的比较（如字符串与整数）时，查询返回FAILURE而不是正确的结果。

示例查询：
```sql
SELECT * FROM join_table_1 INNER JOIN join_table_2 
ON join_table_1.name<join_table_2.age AND join_table_1.id=join_table_2.id;
```

其中 `name` 是 CHARS 类型，`age` 是 INTS 类型。

## 根本原因

在 `src/observer/sql/expr/expression.cpp` 的 `ComparisonExpr::eval` 方法中（原第237-240行），当两列类型不同时，代码会直接返回 `RC::INTERNAL` 错误：

```cpp
if (left_column.attr_type() != right_column.attr_type()) {
    LOG_WARN("cannot compare columns with different types");
    return RC::INTERNAL;
}
```

这导致整个查询执行失败。

## 修复方案

修改了 `ComparisonExpr::eval` 方法，当两列类型不同时，不再直接返回错误，而是使用逐行比较，通过 `Value::compare` 方法处理跨类型比较：

```cpp
// 如果两列类型不同，使用逐行比较（支持跨类型比较）
if (left_column.attr_type() != right_column.attr_type()) {
    int rows = 0;
    if (left_column.column_type() == Column::Type::CONSTANT_COLUMN) {
      rows = right_column.count();
    } else {
      rows = left_column.count();
    }
    for (int i = 0; i < rows; ++i) {
      Value left_val = left_column.get_value(i);
      Value right_val = right_column.get_value(i);
      bool result = false;
      rc = compare_value(left_val, right_val, result);
      if (rc != RC::SUCCESS) {
        LOG_WARN("failed to compare tuple cells. rc=%s", strrc(rc));
        return rc;
      }
      select[i] &= result ? 1 : 0;
    }
    return rc;
}
```

## Docker测试步骤

### 方法1：重新构建Docker镜像

1. **停止并删除现有容器：**
```bash
cd docker
docker-compose down
```

2. **重新构建镜像：**
```bash
docker-compose build --no-cache
```

3. **启动新容器：**
```bash
docker-compose up -d
```

4. **进入容器测试：**
```bash
docker exec -it miniob-container bash
cd /root/miniob

# 运行测试脚本
chmod +x docker/test_join_cross_type.sh
./docker/test_join_cross_type.sh
```

### 方法2：手动测试

1. **进入容器：**
```bash
docker exec -it miniob-container bash
cd /root/miniob
```

2. **重新编译代码：**
```bash
./build.sh debug --make -j8
```

3. **启动observer：**
```bash
build/bin/observer -f etc/observer.ini &
sleep 2
```

4. **运行测试SQL：**
```bash
# 创建表
echo "CREATE TABLE join_table_1(id int, name char(20));" | build/bin/obclient
echo "CREATE TABLE join_table_2(id int, age int);" | build/bin/obclient

# 插入数据
echo "INSERT INTO join_table_1 VALUES (1, '10a');" | build/bin/obclient
echo "INSERT INTO join_table_1 VALUES (2, '20b');" | build/bin/obclient
echo "INSERT INTO join_table_1 VALUES (3, '3c');" | build/bin/obclient
echo "INSERT INTO join_table_1 VALUES (4, '16a');" | build/bin/obclient

echo "INSERT INTO join_table_2 VALUES (1, 15);" | build/bin/obclient
echo "INSERT INTO join_table_2 VALUES (2, 25);" | build/bin/obclient
echo "INSERT INTO join_table_2 VALUES (3, 8);" | build/bin/obclient
echo "INSERT INTO join_table_2 VALUES (4, 5);" | build/bin/obclient

# 执行JOIN查询
echo "SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.name<join_table_2.age AND join_table_1.id=join_table_2.id;" | build/bin/obclient
```

## 预期结果

查询应该正常执行，不再返回FAILURE。根据数据和条件：
- id=1: '10a'(10) < 15 = true，应匹配
- id=2: '20b'(20) < 25 = true，应匹配
- id=3: '3c'(3) < 8 = true，应匹配
- id=4: '16a'(16) < 5 = false，不匹配

所以应该返回前3条记录。

## 类型转换规则

修复后支持以下跨类型比较：
1. **字符串 vs 整数/浮点数**：尝试将字符串转换为数字进行比较
   - '10a' 转换为 10
   - '3.14' 转换为 3.14
   - 'abc' 无法转换，按字典序比较
   
2. **整数 vs 浮点数**：整数自动提升为浮点数进行比较

3. **日期 vs 字符串**：尝试将字符串解析为日期

## 相关文件

- `src/observer/sql/expr/expression.cpp` - 主要修复
- `src/observer/common/type/char_type.cpp` - 字符串类型比较逻辑
- `src/observer/common/type/integer_type.cpp` - 整数类型比较逻辑
- `docker/test_join_cross_type.sh` - 测试脚本

## Git提交

- Commit: `c006da9`
- 消息: "fix join cross type comparison"
- 仓库: https://github.com/ZJZ-STAR/miniob-2025.git

