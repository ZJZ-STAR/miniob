-- 手动测试 drop table 功能

-- 测试1: 创建并删除空表
CREATE TABLE test1(id int);
SHOW TABLES;
DROP TABLE test1;
SHOW TABLES;

-- 测试2: 创建并删除有数据的表
CREATE TABLE test2(id int, name char(10));
INSERT INTO test2 VALUES (1, 'hello');
SELECT * FROM test2;
DROP TABLE test2;
SELECT * FROM test2;

-- 测试3: 删除不存在的表
DROP TABLE nonexistent_table;

-- 测试4: 重新创建已删除的表
CREATE TABLE test3(id int);
DROP TABLE test3;
CREATE TABLE test3(id int, name char(10));
INSERT INTO test3 VALUES (1, 'world');
SELECT * FROM test3;

-- 测试5: 删除带索引的表
CREATE TABLE test4(id int, name char(10));
CREATE INDEX idx_id ON test4(id);
INSERT INTO test4 VALUES (1, 'index');
SELECT * FROM test4;
DROP TABLE test4;
SELECT * FROM test4;

EXIT;
