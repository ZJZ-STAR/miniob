-- DATE类型测试用例
-- 测试创建包含DATE字段的表
CREATE TABLE test_date (
    id INT,
    name CHAR(20),
    birth_date DATE,
    create_date DATE
);

-- 测试插入有效的日期数据
INSERT INTO test_date VALUES (1, 'Alice', '1990-05-15', '2023-01-01');
INSERT INTO test_date VALUES (2, 'Bob', '1985-12-25', '2023-02-14');
INSERT INTO test_date VALUES (3, 'Charlie', '2000-02-29', '2023-03-15'); -- 闰年测试

-- 测试查询DATE字段
SELECT * FROM test_date;

-- 测试DATE字段比较
SELECT * FROM test_date WHERE birth_date > '1990-01-01';
SELECT * FROM test_date WHERE birth_date = '2000-02-29';

-- 测试更新DATE字段
UPDATE test_date SET create_date = '2023-12-31' WHERE id = 1;

-- 再次查询验证更新
SELECT * FROM test_date WHERE id = 1;

-- 测试无效日期（应该失败）
-- INSERT INTO test_date VALUES (4, 'David', '2023-02-30', '2023-01-01'); -- 2月30日不存在
-- INSERT INTO test_date VALUES (5, 'Eve', '2023-13-01', '2023-01-01');  -- 13月不存在
-- INSERT INTO test_date VALUES (6, 'Frank', '2023-01-32', '2023-01-01'); -- 1月32日不存在

-- 测试边界日期
INSERT INTO test_date VALUES (7, 'Grace', '1900-01-01', '2100-12-31'); -- 边界测试

-- 最终查询
SELECT * FROM test_date ORDER BY id;


