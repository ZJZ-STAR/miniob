-- 测试具体的日期查询和索引功能

-- 查询早于1970年的记录
SELECT * FROM test_date WHERE birth < '1970-01-01';
-- 预期结果：id=1（birth='1969-12-31'）

-- 查询超2038年的记录
SELECT * FROM test_date WHERE event_date > '2038-02-01';
-- 预期结果：id=2（event_date='2100-12-31'、'2039-03-15'）

-- 比较闰年日期
SELECT * FROM test_date WHERE birth = '2020-02-29';
-- 预期结果：id=3

-- 创建索引
CREATE INDEX idx_birth ON test_date(birth);

-- 使用索引的查询测试
SELECT * FROM test_date WHERE birth = '2020-02-29';
SELECT * FROM test_date WHERE birth < '1970-01-01';
SELECT * FROM test_date WHERE birth > '2020-01-01';

-- 测试范围查询
SELECT * FROM test_date WHERE birth BETWEEN '2020-01-01' AND '2025-12-31';

exit
