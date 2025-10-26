#!/bin/bash
# 快速测试脚本 - 在Docker容器内运行
# 用法：bash docker/quick-test.sh

set -e  # 遇到错误立即退出

echo "==================================="
echo "🐳 MiniOB Docker 快速测试"
echo "==================================="

# 检查是否在容器内
if [ ! -f /.dockerenv ]; then
    echo "⚠️  警告：此脚本应在Docker容器内运行"
    echo "请先执行："
    echo "  docker exec -it miniob bash"
    echo "  cd /root/miniob"
    echo "  bash docker/quick-test.sh"
    exit 1
fi

# 获取代码目录
CODE_DIR=$(pwd)
echo "📁 代码目录: $CODE_DIR"

# 步骤1：编译
echo ""
echo "📦 步骤1/4: 编译项目..."
if [ ! -d "build_debug" ]; then
    echo "初次编译，先初始化依赖..."
    bash build.sh init
fi

bash build.sh debug --make -j4
if [ $? -ne 0 ]; then
    echo "❌ 编译失败！"
    exit 1
fi
echo "✅ 编译成功"

# 步骤2：单元测试
echo ""
echo "🧪 步骤2/4: 运行单元测试..."
cd build_debug
ctest --output-on-failure -E memtracer_test
if [ $? -ne 0 ]; then
    echo "❌ 单元测试失败！"
    exit 1
fi
echo "✅ 单元测试通过"
cd $CODE_DIR

# 步骤3：基础SQL测试
echo ""
echo "📝 步骤3/4: 运行基础SQL测试..."

# 创建测试SQL
cat > /tmp/quick_test.sql << 'EOF'
-- 基础测试
CREATE TABLE test_basic(id int, name char(20));
INSERT INTO test_basic VALUES (1, 'Alice');
INSERT INTO test_basic VALUES (2, 'Bob');
SELECT * FROM test_basic;
DROP TABLE test_basic;

-- Expression测试
CREATE TABLE test_expr(id int, col1 int, col2 int);
INSERT INTO test_expr VALUES (1, 5, 3);
INSERT INTO test_expr VALUES (2, 8, 4);
INSERT INTO test_expr VALUES (3, 10, 2);

-- 算术表达式
SELECT * FROM test_expr WHERE col1 + col2 > 10;
SELECT * FROM test_expr WHERE -0 < col1 - col2;

-- UPDATE with expression
UPDATE test_expr SET col1=100 WHERE id+1=3;
SELECT * FROM test_expr WHERE id=2;

-- DELETE with expression
DELETE FROM test_expr WHERE col1 - col2 < 3;
SELECT * FROM test_expr;

DROP TABLE test_expr;

-- DATE测试（如果支持）
CREATE TABLE test_date(id int, u_date date);
INSERT INTO test_date VALUES (1,'2020-01-21');
INSERT INTO test_date VALUES (2,'2020-10-21');
INSERT INTO test_date VALUES (3,'2020-1-01');
SELECT * FROM test_date WHERE u_date='2020-1-01';
DROP TABLE test_date;

EOF

# 启动observer（后台）
killall observer 2>/dev/null || true
sleep 1
./build_debug/bin/observer -f etc/observer.ini > /tmp/observer.log 2>&1 &
OBSERVER_PID=$!
sleep 2

# 检查observer是否启动
if ! ps -p $OBSERVER_PID > /dev/null; then
    echo "❌ Observer启动失败！"
    cat /tmp/observer.log
    exit 1
fi

# 执行SQL测试
./build_debug/bin/obclient < /tmp/quick_test.sql > /tmp/test_result.txt 2>&1
SQL_EXIT_CODE=$?

# 停止observer
kill $OBSERVER_PID 2>/dev/null || true
wait $OBSERVER_PID 2>/dev/null || true

if [ $SQL_EXIT_CODE -ne 0 ]; then
    echo "❌ SQL测试失败！"
    cat /tmp/test_result.txt
    exit 1
fi

# 检查结果
if grep -q "FAILURE\|ERROR\|error" /tmp/test_result.txt; then
    echo "❌ SQL测试包含错误！"
    cat /tmp/test_result.txt
    exit 1
fi

echo "✅ 基础SQL测试通过"

# 步骤4：集成测试（可选，比较慢）
echo ""
echo "🔍 步骤4/4: 运行集成测试（可选）..."
read -p "是否运行完整集成测试？这可能需要10-15分钟 (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd test/integration_test
    python3 libminiob_test.py -c conf.ini
    if [ $? -ne 0 ]; then
        echo "❌ 集成测试失败！"
        exit 1
    fi
    echo "✅ 集成测试通过"
else
    echo "⏭️  跳过集成测试"
fi

# 完成
echo ""
echo "==================================="
echo "🎉 所有测试通过！"
echo "==================================="
echo ""
echo "💡 下一步："
echo "  1. 在容器内继续开发和测试"
echo "  2. 确认所有功能正常后，提交代码："
echo "     git add ."
echo "     git commit -m 'your message'"
echo "     git push"
echo "  3. 在GitHub Actions上验证CI"
echo ""
echo "📝 测试结果已保存到："
echo "  - /tmp/test_result.txt (SQL测试输出)"
echo "  - /tmp/observer.log (Observer日志)"
echo ""

