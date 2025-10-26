-- 测试表达式功能
DROP TABLE IF EXISTS exp_table;

CREATE TABLE exp_table(id int, col1 int, col2 int, col3 float, col4 float);

INSERT INTO exp_table VALUES (1, 5, 3, 1.5, 2.5);
INSERT INTO exp_table VALUES (2, 8, 4, 3.0, 1.0);
INSERT INTO exp_table VALUES (3, 10, 2, 5.0, 3.0);

-- 测试1：简单算术表达式
SELECT * FROM exp_table WHERE col1 + col2 > 10;

-- 测试2：负数
SELECT * FROM exp_table WHERE -0 < col1 - col2;

-- 测试3：多个运算
SELECT * FROM exp_table WHERE 5 + col2 < 11;

-- 测试4：浮点数运算
SELECT * FROM exp_table WHERE col3 * 2 > col4;

-- 测试5：UPDATE with expression
UPDATE exp_table SET col1=100 WHERE id+1=3;
SELECT * FROM exp_table;

-- 测试6：DELETE with expression  
DELETE FROM exp_table WHERE col1 - col2 < 3;
SELECT * FROM exp_table;

DROP TABLE exp_table;

