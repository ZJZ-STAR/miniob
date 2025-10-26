-- 最简单的表达式测试
CREATE TABLE t1(a int, b int);
INSERT INTO t1 VALUES (5, 2);
INSERT INTO t1 VALUES (3, 4);

-- 测试1：简单比较（不用表达式）
SELECT * FROM t1 WHERE a > b;

-- 测试2：简单算术表达式
SELECT * FROM t1 WHERE a - b > 0;

-- 测试3：负数
SELECT * FROM t1 WHERE 0 < a - b;

-- 测试4：原始失败的查询
SELECT * FROM t1 WHERE -0 < a - b;

DROP TABLE t1;


