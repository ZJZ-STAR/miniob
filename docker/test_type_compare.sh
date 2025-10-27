#!/bin/bash

cd /root/miniob

# Kill old observer
pkill -9 observer 2>/dev/null

# Clean database
rm -f miniob/*.db miniob/*.log observer.log.*

# Start observer
./build_debug/bin/observer -f etc/observer.ini > /tmp/observer.log 2>&1 &
sleep 3

# Run simple type comparison test
./build_debug/bin/obclient <<EOF
CREATE TABLE test_char(id int, name char);
CREATE TABLE test_int(id int, val int);

INSERT INTO test_char VALUES (1, '10');
INSERT INTO test_char VALUES (2, '20');
INSERT INTO test_int VALUES (1, 15);
INSERT INTO test_int VALUES (2, 25);

-- 测试字符串和整数比较（隐式连接）
SELECT * FROM test_char, test_int WHERE test_char.name < test_int.val;

EXIT
EOF

echo ""
echo "=== Observer Error Log ==="
grep -i "error\|warn\|fail" /tmp/observer.log | tail -20


