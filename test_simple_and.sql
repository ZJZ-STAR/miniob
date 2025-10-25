-- 简单AND测试
CREATE TABLE test_table(id int, value int);

INSERT INTO test_table VALUES (1, 10);
INSERT INTO test_table VALUES (2, 20);
INSERT INTO test_table VALUES (3, 30);
INSERT INTO test_table VALUES (4, 40);

-- 测试单个条件
SELECT * FROM test_table WHERE value > 15;
SELECT * FROM test_table WHERE value < 35;

-- 测试AND条件
SELECT * FROM test_table WHERE value > 15 AND value < 35;

exit
