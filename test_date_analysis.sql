-- 测试日期索引问题的分析脚本
-- 创建测试表
create table date_test(id int, date_col date);

-- 插入测试数据
insert into date_test values (1, '2020-01-21');
insert into date_test values (2, '2020-10-21');
insert into date_test values (3, '2020-1-01');  -- 这个格式可能有问题
insert into date_test values (4, '2000-01-01');
insert into date_test values (5, '2019-12-21');
insert into date_test values (6, '2016-02-29');
insert into date_test values (7, '1970-01-01');
insert into date_test values (8, '1950-02-02');
insert into date_test values (9, '2025-01-01');
insert into date_test values (10, '1950-02-02');

-- 查看所有数据
select * from date_test;

-- 创建索引
create index idx_date on date_test(date_col);

-- 测试各种查询
-- 1. 等值查询
select * from date_test where date_col = '2000-01-01';

-- 2. 不等查询
select * from date_test where date_col <> '2000-01-01';

-- 3. 小于查询
select * from date_test where date_col < '2019-12-21';

-- 4. 组合查询
select * from date_test where date_col <> '2000-01-01' and date_col < '2019-12-21';

-- 5. 测试边界情况
select * from date_test where date_col > '1970-01-01';
select * from date_test where date_col <= '2020-01-01';

exit
