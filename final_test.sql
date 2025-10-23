-- 最终drop table功能测试

-- 测试1: 创建表并验证
CREATE TABLE test_drop(id int);
SHOW TABLES;

-- 测试2: 删除表并验证
DROP TABLE test_drop;
SHOW TABLES;

-- 测试3: 删除不存在的表（应该成功）
DROP TABLE nonexistent_table;

-- 测试4: 创建有数据的表
CREATE TABLE test_data(id int, name char(10));
INSERT INTO test_data VALUES (1, 'test');
SELECT * FROM test_data;

-- 测试5: 删除有数据的表
DROP TABLE test_data;

-- 测试6: 尝试查询已删除的表（应该失败）
SELECT * FROM test_data;

EXIT;
