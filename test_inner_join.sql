-- 测试 INNER JOIN 功能

-- 1. 创建测试表
CREATE TABLE t(id int, name char);
CREATE TABLE t1(id int, score int);
CREATE TABLE t2(id int, age int);

-- 2. 插入测试数据
INSERT INTO t VALUES (1, 'a');
INSERT INTO t VALUES (2, 'b');
INSERT INTO t VALUES (3, 'c');

INSERT INTO t1 VALUES (1, 90);
INSERT INTO t1 VALUES (2, 85);
INSERT INTO t1 VALUES (3, 95);

INSERT INTO t2 VALUES (1, 20);
INSERT INTO t2 VALUES (2, 21);
INSERT INTO t2 VALUES (3, 22);

-- 3. 测试简单的 INNER JOIN
SELECT * FROM t INNER JOIN t1 ON t.id = t1.id;

-- 4. 测试多个 INNER JOIN
SELECT * FROM t INNER JOIN t1 ON t.id = t1.id INNER JOIN t2 ON t.id = t2.id;

-- 5. 测试 INNER JOIN 带 WHERE 条件
SELECT * FROM t INNER JOIN t1 ON t.id = t1.id WHERE t1.score > 85;

-- 6. 测试混合：INNER JOIN + 隐式内连接（逗号）
SELECT * FROM t INNER JOIN t1 ON t.id = t1.id, t2 WHERE t2.id = t.id;

-- 7. 测试 JOIN (不带 INNER 关键字)
SELECT * FROM t JOIN t1 ON t.id = t1.id;

-- 8. 测试 INNER JOIN 带多个 ON 条件
SELECT * FROM t INNER JOIN t1 ON t.id = t1.id AND t1.score > 80;

-- 清理
DROP TABLE t;
DROP TABLE t1;
DROP TABLE t2;

