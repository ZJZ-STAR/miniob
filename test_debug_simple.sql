-- 简单调试测试
CREATE TABLE test_debug(id int, u_date date);
INSERT INTO test_debug VALUES (1, '2020-01-01');
INSERT INTO test_debug VALUES (2, '2019-01-01');
INSERT INTO test_debug VALUES (3, '2000-01-01');

-- 查看所有数据
SELECT * FROM test_debug;

-- 测试单个条件
SELECT * FROM test_debug WHERE u_date <> '2000-01-01';
SELECT * FROM test_debug WHERE u_date < '2019-12-21';

-- 测试组合条件
SELECT * FROM test_debug WHERE u_date <> '2000-01-01' AND u_date < '2019-12-21';

exit
