# 混合JOIN语法支持修复

## 问题描述

包含混合隐式JOIN（逗号）和显式INNER JOIN的查询返回FAILURE。

**失败的查询示例：**
```sql
SELECT join_table_1.id, join_table_1.name, join_table_2.age, join_table_3.level 
FROM join_table_1, join_table_2 
INNER JOIN join_table_3 ON join_table_2.id=join_table_3.id 
WHERE join_table_1.id=join_table_2.id;
```

**错误：** `FAILURE`

## 根本原因

问题出在**语法解析阶段**。

原来的语法规则（`yacc_sql.y` 第501行）只支持一种顺序：

```yacc
SELECT expression_list FROM relation join_list rel_list where group_by
```

这要求：`FROM 第一个表 JOIN子句 逗号表`

但用户的查询是：
```sql
FROM join_table_1, join_table_2 INNER JOIN join_table_3 ...
```

即：`FROM 第一个表 逗号表 JOIN子句` ❌ **不支持！**

解析器在遇到 `COMMA relation` 后期望的是另一个 `COMMA` 或结束，但遇到了 `INNER JOIN`，导致语法解析失败。

## 修复方案

添加了第二个语法规则来支持相反的顺序：

```yacc
| SELECT expression_list FROM relation rel_list join_list where group_by
```

这支持：`FROM 第一个表 逗号表 JOIN子句` ✅

现在解析器支持**两种顺序**：

### 顺序1：JOIN在前，逗号在后（原有）
```sql
SELECT * 
FROM A 
INNER JOIN B ON A.id=B.id, C, D 
WHERE ...;
```

匹配：
- `relation` = A
- `join_list` = INNER JOIN B ON ...
- `rel_list` = C, D

### 顺序2：逗号在前，JOIN在后（新增）
```sql
SELECT * 
FROM A, B, C 
INNER JOIN D ON C.id=D.id 
WHERE ...;
```

匹配：
- `relation` = A
- `rel_list` = B, C
- `join_list` = INNER JOIN D ON ...

## 修改文件

- `src/observer/sql/parser/yacc_sql.y` - 添加替代语法规则

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
echo "CREATE TABLE join_table_2(id int, age int);" | build/bin/obclient
echo "CREATE TABLE join_table_3(id int, level int);" | build/bin/obclient

# 插入数据
echo "INSERT INTO join_table_1 VALUES (1, 'Alice'), (2, 'Bob');" | build/bin/obclient
echo "INSERT INTO join_table_2 VALUES (1, 25), (2, 30);" | build/bin/obclient
echo "INSERT INTO join_table_3 VALUES (1, 5), (2, 8);" | build/bin/obclient

# 测试混合JOIN语法
echo "SELECT join_table_1.id, join_table_1.name, join_table_2.age, join_table_3.level FROM join_table_1, join_table_2 INNER JOIN join_table_3 ON join_table_2.id=join_table_3.id WHERE join_table_1.id=join_table_2.id;" | build/bin/obclient
```

### 预期结果

- ✅ 不显示 `FAILURE`
- ✅ 返回 SUCCESS
- ✅ 正确的查询结果（2行数据）

## 支持的JOIN语法

### 1. 纯隐式JOIN（逗号）
```sql
SELECT * FROM A, B, C WHERE A.id=B.id AND B.id=C.id;
```

### 2. 纯显式JOIN
```sql
SELECT * FROM A 
INNER JOIN B ON A.id=B.id 
INNER JOIN C ON B.id=C.id;
```

### 3. 混合：JOIN在前
```sql
SELECT * FROM A 
INNER JOIN B ON A.id=B.id, C 
WHERE B.id=C.id;
```

### 4. 混合：逗号在前（本次修复）
```sql
SELECT * FROM A, B 
INNER JOIN C ON B.id=C.id 
WHERE A.id=B.id;
```

## SQL标准兼容性

在标准SQL中：
- 逗号和 INNER JOIN 可以混合使用
- INNER JOIN 的优先级高于逗号
- `A, B JOIN C ON ...` 解析为 `A, (B JOIN C ON ...)`

本次修复使 MiniOB 更接近标准SQL行为。

## Git提交

- Commit: `98aefc9`
- 消息: "fix(parser): support mixed implicit and explicit JOIN syntax"
- 仓库: https://github.com/ZJZ-STAR/miniob-2025.git

## 总结

这是一个**语法解析问题**，与之前的跨类型比较问题不同：
- **之前的问题**：逻辑计划生成失败（类型转换）
- **本次问题**：语法解析失败（不支持混合JOIN顺序）

两个问题都已修复，现在支持：
1. ✅ 跨类型比较（CHARS vs INTS）
2. ✅ 混合JOIN语法（逗号 + INNER JOIN）

