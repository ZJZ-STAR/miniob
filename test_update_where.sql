-- 测试UPDATE的WHERE条件是否生效
CREATE TABLE t1(id int, name char(10), age int);
INSERT INTO t1 VALUES (1, 'Alice', 20);
INSERT INTO t1 VALUES (2, 'Bob', 25);
INSERT INTO t1 VALUES (3, 'Charlie', 30);

-- 测试1：简单WHERE条件
UPDATE t1 SET age=21 WHERE id=1;
SELECT * FROM t1;
-- 预期：只有id=1的age变成21，其他不变

-- 测试2：表达式WHERE条件
UPDATE t1 SET name='David' WHERE age > 22;
SELECT * FROM t1;
-- 预期：age>22的行(id=2,3)的name变成David

DROP TABLE t1;


