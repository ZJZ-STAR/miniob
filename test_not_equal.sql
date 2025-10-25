-- 专门测试 <> 操作符
CREATE TABLE test_not_equal(id int, u_date date);
INSERT INTO test_not_equal VALUES (1, '2020-01-01');
INSERT INTO test_not_equal VALUES (2, '2000-01-01');
INSERT INTO test_not_equal VALUES (3, '2019-01-01');

-- 查看所有数据
SELECT * FROM test_not_equal;

-- 测试 <> 操作符
SELECT * FROM test_not_equal WHERE u_date <> '2000-01-01';

-- 测试 = 操作符
SELECT * FROM test_not_equal WHERE u_date = '2000-01-01';

-- 测试 < 操作符
SELECT * FROM test_not_equal WHERE u_date < '2019-12-21';

-- 测试组合条件
SELECT * FROM test_not_equal WHERE u_date <> '2000-01-01' AND u_date < '2019-12-21';

exit
