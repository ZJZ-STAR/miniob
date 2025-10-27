#!/bin/bash

# 测试跨类型比较的JOIN查询修复

echo "=========================================="
echo "测试：JOIN查询中的跨类型比较"
echo "=========================================="

# 创建测试表
echo "创建测试表..."
echo "CREATE TABLE join_table_1(id int, name char(20));" | build/bin/obclient
echo "CREATE TABLE join_table_2(id int, age int);" | build/bin/obclient

# 插入测试数据
echo "插入测试数据..."
echo "INSERT INTO join_table_1 VALUES (1, '10a');" | build/bin/obclient
echo "INSERT INTO join_table_1 VALUES (2, '20b');" | build/bin/obclient
echo "INSERT INTO join_table_1 VALUES (3, '3c');" | build/bin/obclient
echo "INSERT INTO join_table_1 VALUES (4, '16a');" | build/bin/obclient

echo "INSERT INTO join_table_2 VALUES (1, 15);" | build/bin/obclient
echo "INSERT INTO join_table_2 VALUES (2, 25);" | build/bin/obclient
echo "INSERT INTO join_table_2 VALUES (3, 8);" | build/bin/obclient
echo "INSERT INTO join_table_2 VALUES (4, 5);" | build/bin/obclient

# 查看表数据
echo ""
echo "表 join_table_1 的数据:"
echo "SELECT * FROM join_table_1;" | build/bin/obclient

echo ""
echo "表 join_table_2 的数据:"
echo "SELECT * FROM join_table_2;" | build/bin/obclient

# 执行JOIN查询（字符串 < 整数）
echo ""
echo "=========================================="
echo "执行JOIN查询：字符串 < 整数"
echo "SQL: SELECT * FROM join_table_1 INNER JOIN join_table_2"
echo "     ON join_table_1.name<join_table_2.age AND join_table_1.id=join_table_2.id;"
echo "=========================================="
echo ""
echo "预期结果："
echo "- id=1: '10a' (10) < 15 = true  => 应该匹配"
echo "- id=2: '20b' (20) < 25 = true  => 应该匹配"
echo "- id=3: '3c'  (3)  < 8  = true  => 应该匹配"
echo "- id=4: '16a' (16) < 5  = false => 不应该匹配"
echo ""
echo "实际结果："
echo "SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.name<join_table_2.age AND join_table_1.id=join_table_2.id;" | build/bin/obclient

# 测试用户原始查询
echo ""
echo "=========================================="
echo "测试用户原始查询"
echo "=========================================="
echo ""
echo "预期：4 | VWP5F3W9CZAYQ0G | 4 | 5"
echo "（根据字符串 '16a' (16) < 5 = false，应该返回0行或FAILURE）"
echo ""
echo "实际结果："
echo "SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.name<join_table_2.age AND join_table_1.id=join_table_2.id;" | build/bin/obclient | grep -E "^4\s+\|"

# 清理
echo ""
echo "清理测试表..."
echo "DROP TABLE join_table_1;" | build/bin/obclient
echo "DROP TABLE join_table_2;" | build/bin/obclient

echo ""
echo "测试完成！"

