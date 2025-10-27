-- 测试跨类型比较的JOIN查询修复
-- 创建测试表
CREATE TABLE join_table_1(id int, name char(20));
CREATE TABLE join_table_2(id int, age int);

-- 插入测试数据
INSERT INTO join_table_1 VALUES (1, '10a');
INSERT INTO join_table_1 VALUES (2, '20b');
INSERT INTO join_table_1 VALUES (3, '3c');
INSERT INTO join_table_1 VALUES (4, '16a');

INSERT INTO join_table_2 VALUES (1, 15);
INSERT INTO join_table_2 VALUES (2, 25);
INSERT INTO join_table_2 VALUES (3, 8);
INSERT INTO join_table_2 VALUES (4, 5);

-- 测试查询：字符串与整数的跨类型比较
-- join_table_1.name (CHARS) < join_table_2.age (INTS)
-- 预期结果：
-- - id=1: '10a' (转换为10) < 15 = true, AND id=1 = true => 匹配
-- - id=2: '20b' (转换为20) < 25 = true, AND id=2 = true => 匹配
-- - id=3: '3c'  (转换为3)  < 8  = true, AND id=3 = true => 匹配
-- - id=4: '16a' (转换为16) < 5  = false, AND id=4 = true => 不匹配
SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.name<join_table_2.age AND join_table_1.id=join_table_2.id;

-- 清理
DROP TABLE join_table_1;
DROP TABLE join_table_2;

