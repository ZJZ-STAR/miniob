-- 测试UPDATE WHERE是否修复
DROP TABLE IF EXISTS test_update;
CREATE TABLE test_update(id int, name char(20));

INSERT INTO test_update VALUES (1, 'Alice');
INSERT INTO test_update VALUES (2, 'Bob');
INSERT INTO test_update VALUES (3, 'Charlie');

-- 显示初始状态
SELECT * FROM test_update;

-- 测试：只更新id=2的行
UPDATE test_update SET name='Bobby' WHERE id=2;

-- 验证结果：应该只有id=2的行被更新
SELECT * FROM test_update;

-- 测试：使用表达式的WHERE条件
UPDATE test_update SET name='Updated' WHERE id+1=4;

-- 验证结果：应该只有id=3的行被更新
SELECT * FROM test_update;

DROP TABLE test_update;

