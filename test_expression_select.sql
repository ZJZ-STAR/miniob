-- 测试 SELECT 语句中的表达式功能

-- 创建测试表
create table test_expr(id int, col1 int, col2 int, col3 float);

-- 插入测试数据
insert into test_expr values (1, 10, 20, 3.5);
insert into test_expr values (2, 15, 25, 4.5);
insert into test_expr values (3, 20, 30, 5.5);

-- 1. 基础算术表达式
select col1 + col2 from test_expr;
select col1 - col2 from test_expr;
select col1 * col2 from test_expr;
select col1 / col2 from test_expr;

-- 2. 常量与列混合运算
select col1 + 10 from test_expr;
select 100 - col2 from test_expr;
select col1 * 2 from test_expr;
select col3 / 2.5 from test_expr;

-- 3. 复杂表达式
select col1 + col2 * 2 from test_expr;
select (col1 + col2) * col3 from test_expr;
select col1 + col2 - col3 * 2 from test_expr;

-- 4. 负数表达式
select -col1 from test_expr;
select -col1 + col2 from test_expr;

-- 5. WHERE条件中的表达式
select * from test_expr where col1 + col2 > 30;
select * from test_expr where col1 * 2 < 40;
select * from test_expr where col1 - col2 < -5;

-- 6. 同时SELECT多个表达式
select id, col1, col2, col1 + col2 as sum from test_expr;
select id, col1 * 2 as double_col1, col3 + 1.0 as add_one from test_expr;

-- 清理
drop table test_expr;
