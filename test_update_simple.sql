CREATE TABLE test_update (id INT, name CHAR, age INT);
INSERT INTO test_update VALUES (1,'A',25);
INSERT INTO test_update VALUES (2,'B',30);
INSERT INTO test_update VALUES (3,'C',35);
SELECT * FROM test_update;
UPDATE test_update SET age=26 WHERE id=1;
SELECT * FROM test_update;
UPDATE test_update SET name='D' WHERE age=30;
SELECT * FROM test_update;
UPDATE test_update SET age=40;
SELECT * FROM test_update;




