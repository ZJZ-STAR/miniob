-- 最终简单测试
CREATE TABLE simple_test(id int, u_date date);
INSERT INTO simple_test VALUES (1, '2020-01-01');
INSERT INTO simple_test VALUES (2, '2019-01-01');
INSERT INTO simple_test VALUES (3, '2000-01-01');

-- 查看所有数据
SELECT * FROM simple_test;

-- 测试单个条件
SELECT * FROM simple_test WHERE u_date <> '2000-01-01';
SELECT * FROM simple_test WHERE u_date < '2019-12-21';

-- 测试组合条件
SELECT * FROM simple_test WHERE u_date <> '2000-01-01' AND u_date < '2019-12-21';

exit
