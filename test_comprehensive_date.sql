-- 全面的日期功能测试
CREATE TABLE test_date(id int, birth date, event_date date);

-- 早于1970-01-01的日期
INSERT INTO test_date VALUES (1, '1969-12-31', '1900-02-28');
-- 超2038年的日期
INSERT INTO test_date VALUES (2, '2039-03-15', '2100-12-31');
-- 闰年2月29日（2020是闰年）
INSERT INTO test_date VALUES (3, '2020-02-29', '1996-02-29');
-- 非闰年2月28日（2021非闰年）
INSERT INTO test_date VALUES (4, '2021-02-28', '2019-02-28');
-- 月份/日期为单数字（如1月、5日）
INSERT INTO test_date VALUES (5, '2023-1-5', '2024-03-7');

-- 查看所有数据
SELECT * FROM test_date;

-- 测试各种日期比较
SELECT * FROM test_date WHERE birth < '1970-01-01';
SELECT * FROM test_date WHERE birth > '2038-01-01';
SELECT * FROM test_date WHERE birth = '2020-02-29';
SELECT * FROM test_date WHERE birth <> '2021-02-28';

-- 测试组合条件
SELECT * FROM test_date WHERE birth >= '1970-01-01' AND birth <= '2038-01-01';
SELECT * FROM test_date WHERE birth < '1970-01-01' OR birth > '2038-01-01';

exit
