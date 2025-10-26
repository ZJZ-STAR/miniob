-- 测试WHERE条件是否生效
CREATE TABLE test_table(id int, name char(20));
INSERT INTO test_table VALUES (1, 'AAA');
INSERT INTO test_table VALUES (2, 'BBB');
INSERT INTO test_table VALUES (3, 'CCC');

-- 应该只更新id=2的行
UPDATE test_table SET name='XXX' WHERE id=2;

-- 查看结果，应该只有id=2的name变成XXX
SELECT * FROM test_table;

-- 测试DELETE
DELETE FROM test_table WHERE id=1;

-- 应该只剩下id=2和id=3
SELECT * FROM test_table;

-- 测试表达式
CREATE TABLE exp_test(col1 int, col2 int);
INSERT INTO exp_test VALUES (5, 2);
INSERT INTO exp_test VALUES (7, 8);
INSERT INTO exp_test VALUES (9, 4);

-- 测试表达式：col1 - col2 > 0
-- 应该返回 (5,2) 和 (9,4)
SELECT * FROM exp_test WHERE col1 - col2 > 0;

DROP TABLE test_table;
DROP TABLE exp_test;


