# FloatType与CHARS比较崩溃修复

## 问题描述

当JOIN条件中包含浮点数与字符串的比较时，observer服务器崩溃。

**导致崩溃的查询：**
```sql
SELECT * FROM join_table_4 
INNER JOIN join_table_1 
ON join_table_1.name > join_table_4.col 
AND join_table_1.id < join_table_4.id;
```

其中：
- `join_table_1.name` 是 CHARS 类型
- `join_table_4.col` 是 FLOAT 类型

**错误信息：**
```
failed to receive response from observer. 
reason=Failed to receive from server. poll return POLLHUP=16
```

这表明observer进程异常终止（崩溃）。

## 根本原因

在 `src/observer/common/type/float_type.cpp` 的 `FloatType::compare` 方法中，第23行有一个断言：

```cpp
ASSERT(right.attr_type() == AttrType::INTS || right.attr_type() == AttrType::FLOATS, 
       "right type is not numeric");
```

当右侧是 `CHARS` 类型时，这个断言失败，导致程序崩溃。

### 为什么之前没发现？

- `CharType::compare` 已支持与 INTS/FLOATS 比较 ✅
- `IntegerType::compare` 已支持与 CHARS 比较 ✅
- **`FloatType::compare` 不支持与 CHARS 比较** ❌ **导致崩溃**

当查询是 `FLOAT vs CHARS` 时：
- 如果左侧是CHARS，调用 `CharType::compare` ✅ 正常
- 如果左侧是FLOAT，调用 `FloatType::compare` ❌ **崩溃**

## 修复方案

修改 `FloatType::compare` 方法，添加与字符串比较的支持，逻辑与 `CharType` 和 `IntegerType` 一致：

```cpp
int FloatType::compare(const Value &left, const Value &right) const
{
  ASSERT(left.attr_type() == AttrType::FLOATS, "left type is not float");
  
  // 浮点数与浮点数或整数比较
  if (right.attr_type() == AttrType::INTS || right.attr_type() == AttrType::FLOATS) {
    float left_val  = left.get_float();
    float right_val = right.get_float();
    return common::compare_float((void *)&left_val, (void *)&right_val);
  }
  
  // 浮点数与字符串比较：尝试将字符串转换为数字
  if (right.attr_type() == AttrType::CHARS) {
    try {
      const char *str = right.value_.pointer_value_;
      if (str == nullptr) {
        return INT32_MAX;  // 空字符串，无法比较
      }
      
      // 尝试转换为浮点数进行比较
      char *end_ptr;
      double right_num = strtod(str, &end_ptr);
      
      // 检查是否成功转换
      if (end_ptr == str) {
        // 完全无法转换，按字典序比较
        string left_str = left.to_string();
        return common::compare_string(
            (void *)left_str.c_str(), left_str.length(), 
            (void *)str, right.length_);
      }
      
      double left_num = (double)left.get_float();
      
      if (left_num < right_num) return -1;
      else if (left_num > right_num) return 1;
      else return 0;
    } catch (...) {
      return INT32_MAX;
    }
  }
  
  LOG_WARN("unsupported comparison between float and type %d", right.attr_type());
  return INT32_MAX;
}
```

### 转换规则

与 `CharType` 和 `IntegerType` 一致：

1. **字符串可转换为数字**（如 "16.5" → 16.5）：
   - 进行数值比较
   
2. **字符串部分可转换**（如 "16a" → 16）：
   - 使用部分转换的数值比较
   
3. **字符串无法转换**（如 "abc"）：
   - 按字典序比较字符串表示

## 修改文件

- `src/observer/common/type/float_type.cpp` - 添加CHARS比较支持

## Docker测试步骤

### 重要：必须重新构建

```bash
cd docker
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 测试查询

```bash
docker exec -it miniob-container bash
cd /root/miniob

# 创建表
echo "CREATE TABLE join_table_1(id int, name char(20));" | build/bin/obclient
echo "CREATE TABLE join_table_4(id int, col float);" | build/bin/obclient

# 插入数据
echo "INSERT INTO join_table_1 VALUES (1, '15.5'), (2, '18.2');" | build/bin/obclient
echo "INSERT INTO join_table_4 VALUES (1, 16.5), (2, 17.5);" | build/bin/obclient

# 测试 CHARS vs FLOAT 比较（之前会崩溃）
echo "SELECT * FROM join_table_1 INNER JOIN join_table_4 ON join_table_1.name > join_table_4.col;" | build/bin/obclient

# 测试 FLOAT vs CHARS 比较（之前会崩溃）
echo "SELECT * FROM join_table_4 INNER JOIN join_table_1 ON join_table_4.col < join_table_1.name;" | build/bin/obclient
```

### 预期结果

- ✅ 不再崩溃（不显示 POLLHUP 错误）
- ✅ 正常执行查询
- ✅ 返回正确的比较结果

## 跨类型比较完整性

现在所有数值类型都支持与字符串的双向比较：

| 比较类型 | CharType::compare | IntegerType::compare | FloatType::compare |
|---------|-------------------|----------------------|-------------------|
| CHARS vs CHARS | ✅ | - | - |
| CHARS vs INTS | ✅ | ✅ | - |
| CHARS vs FLOATS | ✅ | - | ✅ (本次修复) |
| INTS vs CHARS | ✅ | ✅ | - |
| INTS vs INTS | - | ✅ | - |
| INTS vs FLOATS | - | ✅ | ✅ |
| FLOATS vs CHARS | ✅ | - | ✅ (本次修复) |
| FLOATS vs INTS | - | - | ✅ |
| FLOATS vs FLOATS | - | - | ✅ |

## Git提交历史

1. `4ee853b` - 添加类型转换成本和实现
2. `c006da9` - 修复ComparisonExpr::eval跨类型比较
3. `98aefc9` - 支持混合JOIN语法
4. **`c22f881`** - **修复FloatType与CHARS比较崩溃** (本次)

仓库：https://github.com/ZJZ-STAR/miniob-2025.git

## 相关问题修复

这是**第三个**跨类型比较相关的修复：

1. **逻辑计划生成失败** → 添加类型转换成本和实现 (`4ee853b`)
2. **向量化比较失败** → 修复ComparisonExpr::eval (`c006da9`)
3. **FloatType比较崩溃** → 本次修复 (`c22f881`)

现在跨类型比较应该完全正常工作了！

## 总结

### 问题本质
断言检查过于严格，没有处理字符串类型，导致崩溃。

### 修复方法
为 `FloatType::compare` 添加字符串比较支持，与其他类型保持一致。

### 影响范围
任何涉及 `FLOAT vs CHARS` 的比较操作（WHERE、JOIN ON等）。

