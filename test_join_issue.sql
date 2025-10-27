-- 测试字符串和整数比较的 JOIN 问题

CREATE TABLE join_table_1(id int, name char);
CREATE TABLE join_table_2(id int, age int);

INSERT INTO join_table_1 VALUES (1, '10a');
INSERT INTO join_table_1 VALUES (2, '20a');
INSERT INTO join_table_1 VALUES (3, '30a');
INSERT INTO join_table_1 VALUES (4, '16a');

INSERT INTO join_table_2 VALUES (1, 15);
INSERT INTO join_table_2 VALUES (2, 25);
INSERT INTO join_table_2 VALUES (3, 35);
INSERT INTO join_table_2 VALUES (4, 46);

-- 测试简单的等值 JOIN（应该成功）
SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.id = join_table_2.id;

-- 测试带字符串和整数比较的 JOIN（问题场景）
SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.name < join_table_2.age AND join_table_1.id = join_table_2.id;

-- 先测试单独的字符串和整数比较
SELECT * FROM join_table_1, join_table_2 WHERE join_table_1.name < join_table_2.age AND join_table_1.id = join_table_2.id;

DROP TABLE join_table_1;
DROP TABLE join_table_2;


