-- 测试极端日期值
-- 插入极端日期
INSERT INTO test_date VALUES (14, '0001-01-01', '9999-12-31');
-- 查询验证
SELECT birth, event_date FROM test_date WHERE id=14;

-- 查看所有数据
SELECT * FROM test_date ORDER BY id;

-- 测试极端日期的比较
SELECT * FROM test_date WHERE birth = '0001-01-01';
SELECT * FROM test_date WHERE event_date = '9999-12-31';
SELECT * FROM test_date WHERE birth < '1000-01-01';
SELECT * FROM test_date WHERE event_date > '9000-01-01';

exit
