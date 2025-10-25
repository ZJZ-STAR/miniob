-- 完全干净的测试
CREATE TABLE clean_test(id int, u_date date);
INSERT INTO clean_test VALUES (1, '2020-01-01');
INSERT INTO clean_test VALUES (2, '2019-01-01');
INSERT INTO clean_test VALUES (3, '2000-01-01');

-- 查看所有数据
SELECT * FROM clean_test;

-- 测试单个条件
SELECT * FROM clean_test WHERE u_date <> '2000-01-01';
SELECT * FROM clean_test WHERE u_date < '2019-12-21';

-- 测试组合条件
SELECT * FROM clean_test WHERE u_date <> '2000-01-01' AND u_date < '2019-12-21';

exit
