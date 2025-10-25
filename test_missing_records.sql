-- 测试是否遗漏了符合条件的记录
CREATE TABLE date_table(id int, u_date date);
CREATE INDEX index_id on date_table(u_date);

-- 插入测试数据
INSERT INTO date_table VALUES (1,'2020-01-21');
INSERT INTO date_table VALUES (2,'2020-10-21');
INSERT INTO date_table VALUES (3,'2020-1-01');
INSERT INTO date_table VALUES (4,'2000-01-01');  -- 这个应该被过滤掉
INSERT INTO date_table VALUES (5,'2019-12-21');  -- 这个应该被过滤掉（等于边界）
INSERT INTO date_table VALUES (6,'2016-02-29');
INSERT INTO date_table VALUES (7,'1970-01-01');
INSERT INTO date_table VALUES (8,'2038-01-19');
INSERT INTO date_table VALUES (9,'2042-02-02');
INSERT INTO date_table VALUES (10,'1950-02-02');
INSERT INTO date_table VALUES (11,'2000-01-01');  -- 这个应该被过滤掉
INSERT INTO date_table VALUES (12,'2018-06-15'); -- 这个应该被包含
INSERT INTO date_table VALUES (13,'2015-03-10'); -- 这个应该被包含
INSERT INTO date_table VALUES (14,'2019-12-20'); -- 这个应该被包含

-- 查看所有数据
SELECT * FROM date_table ORDER BY u_date;

-- 测试单个条件
SELECT * FROM date_table WHERE u_date<>'2000-01-01' ORDER BY u_date;
SELECT * FROM date_table WHERE u_date < '2019-12-21' ORDER BY u_date;

-- 测试组合条件
SELECT * FROM date_table WHERE u_date<>'2000-01-01' AND u_date < '2019-12-21' ORDER BY u_date;

exit
