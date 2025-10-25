-- 最终验证修复效果
CREATE TABLE test_final(id int, value int, date_col date);

-- 插入测试数据
INSERT INTO test_final VALUES (1, 10, '2020-01-01');
INSERT INTO test_final VALUES (2, 20, '2015-06-15');
INSERT INTO test_final VALUES (3, 30, '2018-12-31');
INSERT INTO test_final VALUES (4, 40, '2022-03-10');

-- 测试整数AND条件
SELECT * FROM test_final WHERE value > 15 AND value < 35;

-- 测试日期AND条件
SELECT * FROM test_final WHERE date_col <> '2020-01-01' AND date_col < '2020-01-01';

-- 测试原始问题查询
SELECT * FROM test_final WHERE date_col <> '2020-01-01' AND date_col < '2022-01-01';

exit
