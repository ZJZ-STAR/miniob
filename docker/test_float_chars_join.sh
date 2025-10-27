#!/bin/bash

set -e  # 遇到错误立即退出

echo "=============================================="
echo "FloatType vs CHARS JOIN 崩溃测试"
echo "=============================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否在容器内
if [ ! -f "/root/miniob/build.sh" ]; then
    echo -e "${RED}错误: 请在 Docker 容器内运行此脚本${NC}"
    echo "运行: docker exec -it miniob-container bash"
    echo "然后: cd /root/miniob && ./docker/test_float_chars_join.sh"
    exit 1
fi

cd /root/miniob

# 1. 验证源代码
echo "1. 验证源代码修复..."
if grep -q "浮点数与字符串比较" src/observer/common/type/float_type.cpp; then
    echo -e "${GREEN}✓${NC} FloatType::compare(Value) 包含 CHARS 支持"
else
    echo -e "${RED}✗${NC} FloatType::compare(Value) 缺少 CHARS 支持"
    echo "请确保代码已更新到最新版本！"
    exit 1
fi

if grep -q "Column.*called with incompatible" src/observer/common/type/float_type.cpp; then
    echo -e "${GREEN}✓${NC} FloatType::compare(Column) 移除了严格 ASSERT"
else
    echo -e "${YELLOW}!${NC} FloatType::compare(Column) 可能仍有严格 ASSERT"
fi

# 2. 完全清理并重新编译
echo ""
echo "2. 完全清理并重新编译..."
rm -rf build build_debug build_release
./build.sh init
./build.sh debug --make -j8

if [ $? -ne 0 ]; then
    echo -e "${RED}✗${NC} 编译失败"
    exit 1
fi
echo -e "${GREEN}✓${NC} 编译成功"

# 3. 清理环境
echo ""
echo "3. 清理环境..."
pkill -9 observer 2>/dev/null || true
rm -rf miniob/db/*
rm -f observer*.log*
rm -f /tmp/test_*.txt

# 4. 启动 observer（带详细日志）
echo ""
echo "4. 启动 observer..."
export GLOG_v=3  # 启用详细日志
build/bin/observer -f etc/observer.ini > observer_test.log 2>&1 &
OBSERVER_PID=$!
echo "Observer PID: $OBSERVER_PID"

# 等待启动
for i in {1..10}; do
    if ps -p $OBSERVER_PID > /dev/null 2>&1; then
        sleep 1
    else
        echo -e "${RED}✗${NC} Observer 启动失败"
        cat observer_test.log
        exit 1
    fi
done

if ps -p $OBSERVER_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Observer 运行中 (PID: $OBSERVER_PID)"
else
    echo -e "${RED}✗${NC} Observer 已停止"
    exit 1
fi

# 5. 创建表
echo ""
echo "5. 创建测试表..."
echo "CREATE TABLE join_table_1(id int, name char(20));" | build/bin/obclient > /tmp/test_create1.txt 2>&1
if grep -qi "success\|创建成功" /tmp/test_create1.txt || [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} join_table_1 创建成功"
else
    echo -e "${RED}✗${NC} join_table_1 创建失败:"
    cat /tmp/test_create1.txt
fi

echo "CREATE TABLE join_table_4(id int, col float);" | build/bin/obclient > /tmp/test_create2.txt 2>&1
if grep -qi "success\|创建成功" /tmp/test_create2.txt || [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} join_table_4 创建成功"
else
    echo -e "${RED}✗${NC} join_table_4 创建失败:"
    cat /tmp/test_create2.txt
fi

# 6. 插入数据
echo ""
echo "6. 插入测试数据..."
echo "INSERT INTO join_table_1 VALUES (1, '15.5');" | build/bin/obclient > /dev/null 2>&1
echo "INSERT INTO join_table_1 VALUES (2, '18.2');" | build/bin/obclient > /dev/null 2>&1
echo "INSERT INTO join_table_1 VALUES (3, '20a');" | build/bin/obclient > /dev/null 2>&1
echo "INSERT INTO join_table_1 VALUES (4, '16a');" | build/bin/obclient > /dev/null 2>&1

echo "INSERT INTO join_table_4 VALUES (1, 16.5);" | build/bin/obclient > /dev/null 2>&1
echo "INSERT INTO join_table_4 VALUES (2, 17.5);" | build/bin/obclient > /dev/null 2>&1
echo "INSERT INTO join_table_4 VALUES (3, 19.9);" | build/bin/obclient > /dev/null 2>&1

echo -e "${GREEN}✓${NC} 测试数据插入完成"

# 检查 observer 是否仍在运行
if ! ps -p $OBSERVER_PID > /dev/null 2>&1; then
    echo -e "${RED}✗${NC} Observer 在数据插入期间崩溃"
    tail -50 observer_test.log
    exit 1
fi

# 7. 执行测试查询
echo ""
echo "=============================================="
echo "7. 执行测试查询"
echo "=============================================="

# 测试 1: 简单的字符串与浮点数比较
echo ""
echo -e "${YELLOW}测试 1:${NC} 简单 CHARS < FLOAT"
echo "SQL: SELECT * FROM join_table_1 WHERE name < 16.5"
echo "SELECT * FROM join_table_1 WHERE '15.5' < 16.5;" | build/bin/obclient > /tmp/test_q1.txt 2>&1
sleep 1

if ps -p $OBSERVER_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Observer 未崩溃"
    cat /tmp/test_q1.txt
else
    echo -e "${RED}✗${NC} Observer 崩溃！"
    tail -50 observer_test.log
    exit 1
fi

# 测试 2: 用户的原始问题查询
echo ""
echo -e "${YELLOW}测试 2:${NC} 原始崩溃查询"
echo "SQL: SELECT * FROM join_table_4 INNER JOIN join_table_1"
echo "     ON join_table_1.name > join_table_4.col AND join_table_1.id < join_table_4.id"
echo ""

# 记录查询前的进程状态
echo "查询前 Observer PID: $OBSERVER_PID"
ps -p $OBSERVER_PID

# 执行查询
echo "SELECT * FROM join_table_4 INNER JOIN join_table_1 ON join_table_1.name > join_table_4.col AND join_table_1.id < join_table_4.id;" | build/bin/obclient > /tmp/test_q2.txt 2>&1
QUERY_EXIT=$?

# 等待一下确保输出完成
sleep 2

# 检查结果
if ps -p $OBSERVER_PID > /dev/null 2>&1; then
    echo ""
    echo -e "${GREEN}✓✓✓ 成功！Observer 未崩溃！${NC}"
    echo ""
    echo "查询结果:"
    cat /tmp/test_q2.txt
    echo ""
    echo -e "${GREEN}测试通过！${NC}"
else
    echo ""
    echo -e "${RED}✗✗✗ 失败！Observer 崩溃了！${NC}"
    echo ""
    echo "obclient 输出:"
    cat /tmp/test_q2.txt
    echo ""
    echo "Observer 日志（最后 100 行）:"
    tail -100 observer_test.log
    echo ""
    
    # 查找可能的错误信息
    echo "错误关键词搜索:"
    grep -i "assert\|abort\|segmentation\|core\|error\|failed" observer_test.log | tail -20
    
    exit 1
fi

# 8. 更多测试
echo ""
echo -e "${YELLOW}测试 3:${NC} 反向比较 (col < name)"
echo "SELECT * FROM join_table_1 INNER JOIN join_table_4 ON join_table_4.col < join_table_1.name;" | build/bin/obclient > /tmp/test_q3.txt 2>&1
sleep 1

if ps -p $OBSERVER_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 测试 3 通过"
else
    echo -e "${RED}✗${NC} 测试 3 导致崩溃"
    tail -50 observer_test.log
    exit 1
fi

# 清理
echo ""
echo "9. 清理..."
pkill -9 observer 2>/dev/null || true

echo ""
echo "=============================================="
echo -e "${GREEN}所有测试通过！${NC}"
echo "=============================================="

