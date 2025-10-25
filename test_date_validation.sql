-- 测试日期验证和错误处理
-- 分隔符错误（用/或.）
INSERT INTO test_date VALUES (6, '2020/01/01', '2020.02.02');
-- 不完整日期（缺少月/日）
INSERT INTO test_date VALUES (7, '2020-01', '2020');
-- 非日期字符串
INSERT INTO test_date VALUES (8, 'abc', '2020-01-xx');
-- 月份非法（0/13）
INSERT INTO test_date VALUES (9, '2020-00-01', '2020-13-01');
-- 日期非法（超出当月最大天数）
INSERT INTO test_date VALUES (10, '2020-02-30', '2021-04-31'); -- 2月最多29天（2020闰年），4月最多30天
-- 非闰年的2月29日
INSERT INTO test_date VALUES (11, '2021-02-29', '2019-02-29'); -- 2021/2019均非闰年
-- 插入int/float（如时间戳）
INSERT INTO test_date VALUES (12, 1612137600, 3.14); -- 1612137600是2021-02-01的时间戳，但类型为int
-- 插入char类型（长度不符或格式错误）
INSERT INTO test_date VALUES (13, '20200101', '2020-01'); -- '20200101'是char(8)，非date格式

-- 查看当前数据
SELECT * FROM test_date;

-- date与int比较（如用时间戳直接比较）
SELECT * FROM test_date WHERE birth > 1612137600;
-- date与char比较（格式不兼容）
SELECT * FROM test_date WHERE event_date = '20200101';

exit