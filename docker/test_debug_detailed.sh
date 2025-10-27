#!/bin/bash

cd /root/miniob

# Kill old observer
pkill -9 observer 2>/dev/null
sleep 1

# Clean database
rm -rf miniob/*.db miniob/*.log observer.log.* /tmp/observer.log

# Start observer with verbose logging
./build_debug/bin/observer -f etc/observer.ini > /tmp/observer.log 2>&1 &
OBSERVER_PID=$!
echo "Observer PID: $OBSERVER_PID"
sleep 3

# Test step by step
echo "=== Step 1: Create tables ==="
echo "CREATE TABLE join_table_1(id int, name char);" | ./build_debug/bin/obclient

echo ""
echo "=== Step 2: Create second table ==="
echo "CREATE TABLE join_table_2(id int, age int);" | ./build_debug/bin/obclient

echo ""
echo "=== Step 3: Insert data ==="
echo "INSERT INTO join_table_1 VALUES (4, '16a');" | ./build_debug/bin/obclient
echo "INSERT INTO join_table_2 VALUES (4, 46);" | ./build_debug/bin/obclient

echo ""
echo "=== Step 4: Simple SELECT ==="
echo "SELECT * FROM join_table_1, join_table_2 WHERE join_table_1.id = join_table_2.id;" | ./build_debug/bin/obclient

echo ""
echo "=== Step 5: Test string-int comparison in WHERE ==="
echo "SELECT * FROM join_table_1, join_table_2 WHERE join_table_1.name < join_table_2.age AND join_table_1.id = join_table_2.id;" | ./build_debug/bin/obclient

echo ""
echo "=== Step 6: Test with INNER JOIN ==="
echo "SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.name < join_table_2.age AND join_table_1.id = join_table_2.id;" | ./build_debug/bin/obclient

echo ""
echo "=== Observer Log (errors/warnings) ==="
grep -i "error\|warn\|fail\|mismatch" /tmp/observer.log | tail -20

# Kill observer
kill $OBSERVER_PID 2>/dev/null


