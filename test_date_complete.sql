-- 完整的 DATE 类型测试

-- 1. 创建表
CREATE TABLE test_dates (id INT, name CHAR(20), birth DATE, event DATE);

-- 2. 测试插入各种时期的日期
INSERT INTO test_dates VALUES (1, 'Alice', '1990-05-15', '2023-01-01');
INSERT INTO test_dates VALUES (2, 'Bob', '1960-03-10', '1965-12-31');
INSERT INTO test_dates VALUES (3, 'Charlie', '2050-12-31', '2080-06-15');
INSERT INTO test_dates VALUES (4, 'Diana', '2000-02-29', '2004-02-29');
INSERT INTO test_dates VALUES (5, 'Eve', '1900-01-01', '2100-12-31');

-- 3. 查询所有数据
SELECT * FROM test_dates;

-- 4. 测试WHERE比较
SELECT * FROM test_dates WHERE birth > '1970-01-01';
SELECT * FROM test_dates WHERE birth < '1970-01-01';
SELECT * FROM test_dates WHERE birth = '2000-02-29';
SELECT * FROM test_dates WHERE event >= '2023-01-01';

-- 5. 测试 UPDATE
UPDATE test_dates SET event = '2025-06-15' WHERE id = 1;
SELECT * FROM test_dates WHERE id = 1;

-- 6. 测试无效日期
INSERT INTO test_dates VALUES (6, 'Bad1', '2023-02-30', '2023-01-01');
INSERT INTO test_dates VALUES (7, 'Bad2', '2023-13-01', '2023-01-01');
INSERT INTO test_dates VALUES (8, 'Bad3', '2100-02-29', '2023-01-01');
INSERT INTO test_dates VALUES (9, 'Bad4', '2023-04-31', '2023-01-01');

-- 7. 最终查询
SELECT * FROM test_dates;

-- 8. 删除表
DROP TABLE test_dates;

exit

