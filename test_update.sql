-- 测试 UPDATE 功能
-- 创建测试表
CREATE TABLE test_update (
    id INT,
    name VARCHAR(50),
    age INT,
    PRIMARY KEY (id)
);

-- 插入测试数据
INSERT INTO test_update VALUES (1, 'Alice', 25);
INSERT INTO test_update VALUES (2, 'Bob', 30);
INSERT INTO test_update VALUES (3, 'Charlie', 35);

-- 测试不带条件的更新（更新所有记录）
UPDATE test_update SET age = age + 1;

-- 测试带条件的更新
UPDATE test_update SET name = 'Updated' WHERE age > 30;

-- 测试更新主键字段
UPDATE test_update SET id = 10 WHERE name = 'Alice';

-- 查看更新结果
SELECT * FROM test_update;



