CREATE TABLE test_table1(id int);
DROP TABLE test_table1;
CREATE TABLE test_table2(id int, name char(10));
INSERT INTO test_table2 VALUES (1, 'test');
DROP TABLE test_table2;
DROP TABLE non_existent_table;
EXIT;
