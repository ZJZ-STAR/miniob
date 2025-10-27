#!/bin/bash

cd /root/miniob

# Kill old observer
pkill -9 observer 2>/dev/null

# Clean database
rm -f miniob/*.db miniob/*.log

# Start observer
./build_debug/bin/observer -f etc/observer.ini > /tmp/observer.log 2>&1 &
sleep 3

# Run test
./build_debug/bin/obclient <<EOF
CREATE TABLE join_table_1(id int, name char);
CREATE TABLE join_table_2(id int, age int);
INSERT INTO join_table_1 VALUES (4, '16a');
INSERT INTO join_table_2 VALUES (4, 46);
SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.id = join_table_2.id;
SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.name < join_table_2.age AND join_table_1.id = join_table_2.id;
SELECT * FROM join_table_1, join_table_2 WHERE join_table_1.name < join_table_2.age AND join_table_1.id = join_table_2.id;
EOF

# Show log if there's an error
if [ $? -ne 0 ]; then
    echo "=== Observer Log ==="
    tail -100 /tmp/observer.log
fi


