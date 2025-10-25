-- Test date comparison with NOT_EQUAL and AND operations
CREATE TABLE date_table(id int, u_date date);
CREATE INDEX index_id on date_table(u_date);

INSERT INTO date_table VALUES (1,'2020-01-21');
INSERT INTO date_table VALUES (2,'2020-10-21');
INSERT INTO date_table VALUES (3,'2020-1-01');
INSERT INTO date_table VALUES (4,'2000-01-01');
INSERT INTO date_table VALUES (5,'2019-12-21');
INSERT INTO date_table VALUES (6,'2016-02-29');
INSERT INTO date_table VALUES (7,'1970-01-01');
INSERT INTO date_table VALUES (8,'2038-01-19');
INSERT INTO date_table VALUES (9,'2042-02-02');
INSERT INTO date_table VALUES (10,'1950-02-02');
INSERT INTO date_table VALUES (11,'2000-01-01');

-- View all data
SELECT * FROM date_table;

-- Test NOT_EQUAL with AND: should return rows where u_date != '2000-01-01' AND u_date < '2019-12-21'
-- Expected: (10, 1950-02-02), (6, 2016-02-29), (7, 1970-01-01)
SELECT * FROM date_table WHERE u_date<>'2000-01-01' and u_date < '2019-12-21';

-- Test individual conditions
SELECT * FROM date_table WHERE u_date<>'2000-01-01';
SELECT * FROM date_table WHERE u_date < '2019-12-21';

exit

