-- 调试执行计划
CREATE TABLE debug_table(id int, value int);

INSERT INTO debug_table VALUES (1, 10);
INSERT INTO debug_table VALUES (2, 20);
INSERT INTO debug_table VALUES (3, 30);
INSERT INTO debug_table VALUES (4, 40);

-- 测试简单AND条件
SELECT * FROM debug_table WHERE value > 15 AND value < 35;

-- 查看执行计划
EXPLAIN SELECT * FROM debug_table WHERE value > 15 AND value < 35;

exit
