CREATE TABLE date_table(id int, u_date date);
INSERT INTO date_table VALUES (1,'2020-01-21');
INSERT INTO date_table VALUES (2,'2020-10-21');
INSERT INTO date_table VALUES (3,'2020-1-01');
INSERT INTO date_table VALUES (9,'2038-01-19');
INSERT INTO date_table VALUES (11,'2042-02-02');
SELECT * FROM date_table;
SELECT * FROM date_table WHERE u_date>'2020-1-20';
exit













