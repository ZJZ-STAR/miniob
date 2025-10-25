-- 测试是否是索引导致的问题
CREATE TABLE date_table(id int, u_date date);
-- 先不创建索引，测试查询
INSERT INTO date_table VALUES (1,'2020-01-21');
INSERT INTO date_table VALUES (2,'2020-10-21');
INSERT INTO date_table VALUES (3,'2020-1-01');
INSERT INTO date_table VALUES (4,'2000-01-01');
INSERT INTO date_table VALUES (5,'2019-12-21');
INSERT INTO date_table VALUES (6,'2016-02-29');
INSERT INTO date_table VALUES (7,'1970-01-01');
INSERT INTO date_table VALUES (8,'2038-01-19');
INSERT INTO date_table VALUES (9,'2042-02-02');
INSERT INTO date_table VALUES (10,'1950-02-02');
INSERT INTO date_table VALUES (11,'2000-01-01');
INSERT INTO date_table VALUES (12,'2018-06-15');
INSERT INTO date_table VALUES (13,'2015-03-10');
INSERT INTO date_table VALUES (14,'2019-12-20');

-- 不使用索引的查询
SELECT * FROM date_table WHERE u_date<>'2000-01-01' AND u_date < '2019-12-21' ORDER BY u_date;

-- 现在创建索引
CREATE INDEX index_id on date_table(u_date);

-- 使用索引的查询
SELECT * FROM date_table WHERE u_date<>'2000-01-01' AND u_date < '2019-12-21' ORDER BY u_date;

exit
