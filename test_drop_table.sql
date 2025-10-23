-- DROP TABLE功能测试脚本
create database test_db;
use test_db;

-- 1. 测试删除空表
create table test_table1(id int, name char(10));
drop table test_table1;

-- 2. 测试删除非空表
create table test_table2(id int, name char(10));
insert into test_table2 values(1, 'test');
select * from test_table2;
drop table test_table2;

-- 3. 测试删除不存在的表
drop table non_exist_table;

-- 4. 测试重新创建已删除的表
create table test_table3(id int, name char(10));
drop table test_table3;
create table test_table3(id int, name char(10));
select * from test_table3;

-- 5. 测试删除带索引的表
create table test_table4(id int, name char(10));
create index idx_id on test_table4(id);
insert into test_table4 values(1, 'test');
select * from test_table4;
drop table test_table4;

-- 6. 验证表确实被删除
select * from test_table4;

exit;
