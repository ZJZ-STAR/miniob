#!/bin/bash

cd /root/miniob

# Kill old observer
pkill -9 observer 2>/dev/null

# Clean database
rm -f miniob/*.db miniob/*.log observer.log.*

# Start observer
./build_debug/bin/observer -f etc/observer.ini > /tmp/observer.log 2>&1 &
sleep 3

# Run test with detailed output
./build_debug/bin/obclient <<EOF
CREATE TABLE join_table_1(id int, name char);
CREATE TABLE join_table_2(id int, age int);
INSERT INTO join_table_1 VALUES (4, '16a');
INSERT INTO join_table_2 VALUES (4, 46);

-- 测试简单查询
SELECT * FROM join_table_1;
SELECT * FROM join_table_2;

-- 测试简单的等值 JOIN（应该成功）
SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.id = join_table_2.id;

-- 测试带字符串和整数比较的 JOIN
SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.name < join_table_2.age AND join_table_1.id = join_table_2.id;

-- 测试隐式连接相同的条件
SELECT * FROM join_table_1, join_table_2 WHERE join_table_1.name < join_table_2.age AND join_table_1.id = join_table_2.id;

-- 测试只有字符串和整数比较条件
SELECT * FROM join_table_1, join_table_2 WHERE join_table_1.name < join_table_2.age;

EXIT
EOF

echo ""
echo "=== Observer Log (last 50 lines) ==="
tail -50 /tmp/observer.log


