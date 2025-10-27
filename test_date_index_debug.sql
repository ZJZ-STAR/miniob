-- 测试日期索引和查询问题
-- 创建测试表
DROP TABLE IF EXISTS date_table;
CREATE TABLE date_table(id int, u_date date);

-- 插入测试数据
INSERT INTO date_table VALUES (1,'2020-01-21');
INSERT INTO date_table VALUES (2,'2020-10-21');
INSERT INTO date_table VALUES (3,'2020-1-01');
INSERT INTO date_table VALUES (4,'2000-01-01');
INSERT INTO date_table VALUES (5,'2019-12-21');
INSERT INTO date_table VALUES (6,'2016-02-29');
INSERT INTO date_table VALUES (7,'1970-01-01');
INSERT INTO date_table VALUES (8,'1950-02-02');
INSERT INTO date_table VALUES (9,'2025-01-01');
INSERT INTO date_table VALUES (10,'1950-02-02');

-- 显示所有数据
SELECT * FROM date_table ORDER BY u_date;

-- 创建索引
CREATE INDEX index_date ON date_table(u_date);

-- 测试查询：u_date<>'2000-01-01' and u_date < '2019-12-21'
SELECT * FROM date_table WHERE u_date<>'2000-01-01' AND u_date < '2019-12-21';

-- 分别测试每个条件
SELECT 'Testing u_date<>''2000-01-01'':';
SELECT * FROM date_table WHERE u_date<>'2000-01-01';

SELECT 'Testing u_date < ''2019-12-21'':';
SELECT * FROM date_table WHERE u_date < '2019-12-21';

-- 测试日期比较的边界情况
SELECT 'Testing date comparisons:';
SELECT id, u_date, 
       CASE 
         WHEN u_date = '2000-01-01' THEN 'EQUAL'
         WHEN u_date < '2000-01-01' THEN 'LESS'
         WHEN u_date > '2000-01-01' THEN 'GREATER'
         ELSE 'UNKNOWN'
       END as comparison_with_2000_01_01
FROM date_table;

SELECT id, u_date, 
       CASE 
         WHEN u_date = '2019-12-21' THEN 'EQUAL'
         WHEN u_date < '2019-12-21' THEN 'LESS'
         WHEN u_date > '2019-12-21' THEN 'GREATER'
         ELSE 'UNKNOWN'
       END as comparison_with_2019_12_21
FROM date_table;




















