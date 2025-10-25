-- 完整的日期AND条件测试
CREATE TABLE date_table(id int, u_date date);

-- 插入符合条件的记录（u_date≠'2000-01-01' 且 u_date < '2019-12-21'）
INSERT INTO date_table VALUES (10, '1950-02-02');  -- 示例中缺失的记录1
INSERT INTO date_table VALUES (6, '2016-02-29');   -- 示例中缺失的记录2（2016是闰年，日期合法）
INSERT INTO date_table VALUES (7, '1970-01-01');   -- 示例中缺失的记录3
INSERT INTO date_table VALUES (9, '2019-12-20');   -- 额外符合条件的记录（临界值前一天）

-- 插入不符合条件的记录（用于验证是否被正确排除）
INSERT INTO date_table VALUES (4, '2000-01-01');   -- 不符合：u_date等于'2000-01-01'
INSERT INTO date_table VALUES (5, '2019-12-21');   -- 不符合：u_date不小于'2019-12-21'（等于临界值）
INSERT INTO date_table VALUES (8, '2020-01-01');   -- 不符合：u_date大于'2019-12-21'
INSERT INTO date_table VALUES (11, '1999-05-01');  -- 不符合：虽然u_date<2019-12-21，但假设实际测试中需排除（此处仅为多样性）

-- 查看所有数据
SELECT * FROM date_table ORDER BY u_date;

-- 测试单个条件
SELECT * FROM date_table WHERE u_date<>'2000-01-01' ORDER BY u_date;
SELECT * FROM date_table WHERE u_date < '2019-12-21' ORDER BY u_date;

-- 测试组合条件
SELECT * FROM date_table WHERE u_date<>'2000-01-01' AND u_date < '2019-12-21' ORDER BY u_date;

exit
