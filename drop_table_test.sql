-- Drop table 功能测试

-- 1. 创建数据库
CREATE DATABASE test_db;
USE test_db;

-- 2. 测试删除空表
CREATE TABLE Drop_table_1(id int, t_name char(10));
DROP TABLE Drop_table_1;

-- 3. 测试删除非空表
CREATE TABLE Drop_table_2(id int, t_name char(10));
INSERT INTO Drop_table_2 VALUES (1,'OB');
DROP TABLE Drop_table_2;

-- 4. 测试删除表的准确性
CREATE TABLE Drop_table_3(id int, t_name char(10));
INSERT INTO Drop_table_3 VALUES (1,'OB');
DROP TABLE Drop_table_3;

-- 5. 测试删除不存在的表
CREATE TABLE Drop_table_4(id int, t_name char(10));
DROP TABLE Drop_table_4;
DROP TABLE Drop_table_4;
DROP TABLE Drop_table_4_1;

-- 6. 测试重新创建已删除的表
CREATE TABLE Drop_table_5(id int, t_name char(10));
DROP TABLE Drop_table_5;
CREATE TABLE Drop_table_5(id int, t_name char(10));
SELECT * FROM Drop_table_5;

-- 7. 测试删除带索引的表
CREATE TABLE Drop_table_6(id int, t_name char(10));
CREATE INDEX index_id ON Drop_table_6(id);
INSERT INTO Drop_table_6 VALUES (1,'OB');
DROP TABLE Drop_table_6;

-- 8. 验证表确实被删除
SELECT * FROM Drop_table_6;

-- 退出
EXIT;
