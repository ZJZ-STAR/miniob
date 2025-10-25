-- 完整诊断测试
-- 1. 首先检查表是否存在和数据是否插入成功
CREATE TABLE date_table(id int, u_date date);
CREATE INDEX index_id on date_table(u_date);

-- 插入所有数据，包括可能有问题的时间
INSERT INTO date_table VALUES (1,'2020-01-21');
INSERT INTO date_table VALUES (2,'2020-10-21');
INSERT INTO date_table VALUES (3,'2020-1-01');
INSERT INTO date_table VALUES (4,'2000-01-01');
INSERT INTO date_table VALUES (5,'2019-12-21');
INSERT INTO date_table VALUES (6,'2016-02-29');  -- 闰年2月29日
INSERT INTO date_table VALUES (7,'1970-01-01');  -- 1970年边界
INSERT INTO date_table VALUES (8,'2038-01-19');
INSERT INTO date_table VALUES (9,'2042-02-02');
INSERT INTO date_table VALUES (10,'1950-02-02'); -- 早于1970年
INSERT INTO date_table VALUES (11,'2000-01-01');

-- 查看所有数据，验证插入是否成功
SELECT * FROM date_table ORDER BY id;

-- 测试单个条件
SELECT * FROM date_table WHERE u_date <> '2000-01-01';
SELECT * FROM date_table WHERE u_date < '2019-12-21';

-- 测试组合条件
SELECT * FROM date_table WHERE u_date <> '2000-01-01' AND u_date < '2019-12-21';

-- 特别检查可能有问题的记录
SELECT * FROM date_table WHERE id IN (6, 7, 10);
SELECT * FROM date_table WHERE u_date = '1950-02-02';
SELECT * FROM date_table WHERE u_date = '2016-02-29';
SELECT * FROM date_table WHERE u_date = '1970-01-01';

exit
