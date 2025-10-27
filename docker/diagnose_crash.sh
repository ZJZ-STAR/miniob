#!/bin/bash

echo "=== 诊断 FloatType 崩溃问题 ==="
echo ""

# 检查源代码版本
echo "1. 检查源代码是否包含修复..."
if grep -q "浮点数与字符串比较" /root/miniob/src/observer/common/type/float_type.cpp; then
    echo "✅ FloatType::compare(Value, Value) 包含字符串比较修复"
else
    echo "❌ FloatType::compare(Value, Value) 没有字符串比较修复"
    exit 1
fi

# 检查 Column 版本的 compare
echo ""
echo "2. 检查 Column 版本的 compare..."
grep -A 5 "compare(const Column &left, const Column &right" /root/miniob/src/observer/common/type/float_type.cpp | head -10

# 重新编译
echo ""
echo "3. 重新编译（调试模式，保留符号）..."
cd /root/miniob
./build.sh debug --make -j8 > /tmp/build.log 2>&1
if [ $? -eq 0 ]; then
    echo "✅ 编译成功"
else
    echo "❌ 编译失败"
    tail -50 /tmp/build.log
    exit 1
fi

# 启用 core dump
echo ""
echo "4. 启用 core dump..."
ulimit -c unlimited
echo "/tmp/core.%e.%p" > /proc/sys/kernel/core_pattern

# 杀死旧进程
echo ""
echo "5. 清理旧进程和数据..."
pkill -9 observer
rm -rf /root/miniob/miniob/db/*
rm -f /root/miniob/observer.log*
rm -f /tmp/core.*

# 启动 observer（使用 gdb 捕获崩溃）
echo ""
echo "6. 启动 observer（带调试）..."
cd /root/miniob
build/bin/observer -f etc/observer.ini > observer_test.log 2>&1 &
OBSERVER_PID=$!
echo "Observer PID: $OBSERVER_PID"
sleep 3

# 检查进程是否启动
if ! ps -p $OBSERVER_PID > /dev/null; then
    echo "❌ Observer 启动失败"
    cat observer_test.log
    exit 1
fi
echo "✅ Observer 启动成功"

# 创建测试表
echo ""
echo "7. 创建测试表..."
echo "CREATE TABLE join_table_1(id int, name char(20));" | build/bin/obclient > /dev/null
echo "CREATE TABLE join_table_4(id int, col float);" | build/bin/obclient > /dev/null

# 插入数据
echo "INSERT INTO join_table_1 VALUES (1, '15.5'), (2, '18.2'), (4, '16a');" | build/bin/obclient > /dev/null
echo "INSERT INTO join_table_4 VALUES (1, 16.5), (2, 17.5);" | build/bin/obclient > /dev/null

echo "✅ 测试数据插入成功"

# 执行崩溃查询
echo ""
echo "8. 执行测试查询..."
echo "查询: SELECT * FROM join_table_4 INNER JOIN join_table_1"
echo "      ON join_table_1.name > join_table_4.col AND join_table_1.id < join_table_4.id"
echo ""

echo "SELECT * FROM join_table_4 INNER JOIN join_table_1 ON join_table_1.name > join_table_4.col AND join_table_1.id < join_table_4.id;" | build/bin/obclient > /tmp/query_result.txt 2>&1

QUERY_EXIT=$?
sleep 2

# 检查结果
if ps -p $OBSERVER_PID > /dev/null; then
    echo ""
    echo "✅ Observer 仍在运行 - 查询成功！"
    echo ""
    echo "查询结果:"
    cat /tmp/query_result.txt
else
    echo ""
    echo "❌ Observer 崩溃了！"
    echo ""
    echo "查询输出:"
    cat /tmp/query_result.txt
    echo ""
    echo "Observer 日志最后 100 行:"
    tail -100 observer_test.log
    echo ""
    
    # 检查 core dump
    if ls /tmp/core.* 2>/dev/null; then
        echo "发现 core dump 文件:"
        ls -lh /tmp/core.*
        echo ""
        echo "使用 gdb 分析堆栈（如果可用）:"
        CORE_FILE=$(ls /tmp/core.* | head -1)
        if command -v gdb &> /dev/null; then
            gdb -batch -ex "bt" build/bin/observer $CORE_FILE 2>&1 | head -50
        fi
    fi
fi

# 清理
pkill -9 observer

echo ""
echo "=== 诊断完成 ==="

