-- 步骤1: 创建表
create table date_table(id int, u_date date);

-- 步骤2: 插入测试数据
insert into date_table values (1,'2020-01-21');
insert into date_table values (2,'2020-10-21');
insert into date_table values (3,'2020-1-01');
insert into date_table values (4,'2000-01-01');
insert into date_table values (5,'2019-12-21');
insert into date_table values (6,'2016-02-29');
insert into date_table values (7,'1970-01-01');
insert into date_table values (8,'1950-02-02');
insert into date_table values (9,'2025-01-01');
insert into date_table values (10,'1950-02-02');

-- 步骤3: 查看所有数据
select * from date_table;

-- 步骤4: 创建索引
create index index_date on date_table(u_date);

-- 步骤5: 测试简单查询
select * from date_table where u_date = '2000-01-01';

-- 步骤6: 测试不等查询
select * from date_table where u_date <> '2000-01-01';

-- 步骤7: 测试小于查询
select * from date_table where u_date < '2019-12-21';

-- 步骤8: 测试组合查询
select * from date_table where u_date <> '2000-01-01' and u_date < '2019-12-21';

exit
