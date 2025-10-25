-- 简单测试，不使用索引
CREATE TABLE date_table(id int, u_date date);
-- 不创建索引

INSERT INTO date_table VALUES (1,'2020-01-21');
INSERT INTO date_table VALUES (2,'2020-10-21');
INSERT INTO date_table VALUES (3,'2020-1-01');
INSERT INTO date_table VALUES (4,'2000-01-01');
INSERT INTO date_table VALUES (5,'2019-12-21');
INSERT INTO date_table VALUES (6,'2016-02-29');
INSERT INTO date_table VALUES (7,'1970-01-01');
INSERT INTO date_table VALUES (10,'1950-02-02');
INSERT INTO date_table VALUES (11,'2000-01-01');
INSERT INTO date_table VALUES (12,'2018-06-15');
INSERT INTO date_table VALUES (13,'2015-03-10');
INSERT INTO date_table VALUES (14,'2019-12-20');

-- 测试单个条件
SELECT * FROM date_table WHERE u_date<>'2000-01-01';
SELECT * FROM date_table WHERE u_date < '2019-12-21';

-- 测试组合条件
SELECT * FROM date_table WHERE u_date<>'2000-01-01' AND u_date < '2019-12-21';

exit
