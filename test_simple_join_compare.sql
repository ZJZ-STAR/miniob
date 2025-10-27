CREATE TABLE join_table_1(id int, name char);
CREATE TABLE join_table_2(id int, age int);
INSERT INTO join_table_1 VALUES (4, '16a');
INSERT INTO join_table_2 VALUES (4, 46);
SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.id = join_table_2.id;
SELECT * FROM join_table_1 INNER JOIN join_table_2 ON join_table_1.name < join_table_2.age AND join_table_1.id = join_table_2.id;

