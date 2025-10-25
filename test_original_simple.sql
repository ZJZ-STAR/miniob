-- 测试原始查询（简化数据）
CREATE TABLE date_table(id int, u_date date);
CREATE INDEX index_id on date_table(u_date);

INSERT INTO date_table VALUES (1,'2020-01-21');
INSERT INTO date_table VALUES (2,'2019-01-21');
INSERT INTO date_table VALUES (3,'2000-01-01');
INSERT INTO date_table VALUES (4,'2016-02-29');
INSERT INTO date_table VALUES (5,'1970-01-01');
INSERT INTO date_table VALUES (6,'1950-02-02');

-- 查看所有数据
SELECT * FROM date_table ORDER BY u_date;

-- 测试单个条件
SELECT * FROM date_table WHERE u_date <> '2000-01-01';
SELECT * FROM date_table WHERE u_date < '2019-12-21';

-- 测试组合条件
SELECT * FROM date_table WHERE u_date <> '2000-01-01' AND u_date < '2019-12-21';

exit
