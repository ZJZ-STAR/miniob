-- DATE类型完整测试用例

-- 1. 测试创建包含DATE字段的表
CREATE TABLE test_date (
    id INT,
    name CHAR(20),
    birth_date DATE,
    event_date DATE
);

-- 2. 测试插入有效的日期数据
INSERT INTO test_date VALUES (1, 'Alice', '1990-05-15', '2023-01-01');
INSERT INTO test_date VALUES (2, 'Bob', '1985-12-25', '2023-02-14');
INSERT INTO test_date VALUES (3, 'Charlie', '2000-02-29', '2023-03-15');  -- 闰年2月29日

-- 3. 测试查询DATE字段
SELECT * FROM test_date;

-- 4. 测试DATE字段比较
SELECT * FROM test_date WHERE birth_date > '1990-01-01';
SELECT * FROM test_date WHERE birth_date = '2000-02-29';

-- 5. 测试更新DATE字段
UPDATE test_date SET event_date = '2023-12-31' WHERE id = 1;
SELECT * FROM test_date WHERE id = 1;

-- 6. 测试边界日期 (1900-2100范围)
INSERT INTO test_date VALUES (4, 'Grace', '1900-01-01', '2100-12-31');
INSERT INTO test_date VALUES (5, 'Henry', '1950-06-15', '2050-07-20');

-- 7. 测试1970年之前的日期
INSERT INTO test_date VALUES (6, 'Ivan', '1960-03-10', '1965-11-22');
INSERT INTO test_date VALUES (7, 'Jane', '1945-08-15', '1969-12-31');

-- 8. 测试2038年之后的日期
INSERT INTO test_date VALUES (8, 'Kevin', '2040-01-01', '2050-12-31');
INSERT INTO test_date VALUES (9, 'Linda', '2060-06-30', '2080-09-15');

-- 9. 查询所有数据
SELECT * FROM test_date ORDER BY id;

-- 10. 测试无效日期（应该失败）
INSERT INTO test_date VALUES (10, 'Mary', '2023-02-30', '2023-01-01');  -- 2月30日不存在
INSERT INTO test_date VALUES (11, 'Nancy', '2023-13-01', '2023-01-01'); -- 13月不存在
INSERT INTO test_date VALUES (12, 'Oscar', '2023-01-32', '2023-01-01'); -- 1月32日不存在
INSERT INTO test_date VALUES (13, 'Peter', '2100-02-29', '2023-01-01'); -- 2100年不是闰年

-- 11. 最终查询验证
SELECT * FROM test_date;

-- 清理
DROP TABLE test_date;

