#!/bin/bash
cd /root/miniob

# 清理并启动 observer
pkill -9 observer
rm -rf miniob/db/*
build_debug/bin/observer -f etc/observer.ini >/dev/null 2>&1 &
sleep 3

# 创建表
echo "CREATE TABLE join_table_1(id int, name char(20));" | build_debug/bin/obclient
echo "CREATE TABLE join_table_2(id int, age int);" | build_debug/bin/obclient
echo "CREATE TABLE join_table_4(id int, col float);" | build_debug/bin/obclient

# 插入数据
echo "INSERT INTO join_table_1 VALUES (4, '16a');" | build_debug/bin/obclient
echo "INSERT INTO join_table_2 VALUES (4, 5);" | build_debug/bin/obclient
echo "INSERT INTO join_table_4 VALUES(1, 16.5);" | build_debug/bin/obclient

# 测试查询1: CHARS < INTS
echo ""
echo "=== 测试1: CHARS < INTS ==="
echo "SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.name<join_table_2.age AND join_table_1.id=join_table_2.id;"
echo "SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.name<join_table_2.age AND join_table_1.id=join_table_2.id;" | build_debug/bin/obclient

# 检查 observer 是否仍在运行
sleep 1
if ps aux | grep -q "[o]bserver"; then
    echo "✅ Observer 仍在运行"
else
    echo "❌ Observer 崩溃了"
    exit 1
fi

# 测试查询2: CHARS > FLOAT
echo ""
echo "=== 测试2: CHARS > FLOAT ==="
echo "SELECT * FROM join_table_4 INNER JOIN join_table_1 ON join_table_1.name>join_table_4.col AND join_table_1.id<join_table_4.id;"
echo "SELECT * FROM join_table_4 INNER JOIN join_table_1 ON join_table_1.name>join_table_4.col AND join_table_1.id<join_table_4.id;" | build_debug/bin/obclient

# 再次检查
sleep 1
if ps aux | grep -q "[o]bserver"; then
    echo "✅ Observer 仍在运行 - 所有测试通过！"
else
    echo "❌ Observer 崩溃了"
    exit 1
fi

echo ""
echo "🎉 所有测试完成！"

