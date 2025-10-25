-- 测试日期索引问题的详细分析
-- 创建测试表
create table date_table(id int, u_date date);

-- 插入测试数据
insert into date_table values (1,'2020-01-21');
insert into date_table values (2,'2020-10-21');
insert into date_table values (3,'2020-01-01');
insert into date_table values (4,'2000-01-01');
insert into date_table values (5,'2019-12-21');
insert into date_table values (6,'2016-02-29');
insert into date_table values (7,'1970-01-01');
insert into date_table values (8,'1950-02-02');
insert into date_table values (9,'2025-01-01');
insert into date_table values (10,'1950-02-02');

-- 查看所有数据
select * from date_table;

-- 创建索引
create index index_date on date_table(u_date);

-- 测试原始查询
select * from date_table where u_date<>'2000-01-01' and u_date < '2019-12-21';

-- 分别测试每个条件
select 'Testing u_date<>''2000-01-01'':';
select * from date_table where u_date<>'2000-01-01';

select 'Testing u_date < ''2019-12-21'':';
select * from date_table where u_date < '2019-12-21';

-- 测试日期比较的边界情况
select 'Testing date comparisons:';
select id, u_date, 
       case 
         when u_date = '2000-01-01' then 'EQUAL'
         when u_date < '2000-01-01' then 'LESS'
         when u_date > '2000-01-01' then 'GREATER'
         else 'UNKNOWN'
       end as comparison_with_2000_01_01
from date_table;

select id, u_date, 
       case 
         when u_date = '2019-12-21' then 'EQUAL'
         when u_date < '2019-12-21' then 'LESS'
         when u_date > '2019-12-21' then 'GREATER'
         else 'UNKNOWN'
       end as comparison_with_2019_12_21
from date_table;

-- 测试索引是否被使用
explain select * from date_table where u_date<>'2000-01-01' and u_date < '2019-12-21';

exit
