# Docker本地测试指南

## 🐳 为什么使用Docker测试？

在本地Windows环境下，Docker可以提供：
- ✅ **Linux环境** - 与CI环境完全一致（Ubuntu 24.04）
- ✅ **快速反馈** - 无需等待GitHub Actions
- ✅ **完整测试** - 编译、单元测试、集成测试
- ✅ **可重复性** - 隔离的干净环境

---

## 📋 前置要求

### 1. 安装Docker Desktop
- 下载：https://www.docker.com/products/docker-desktop
- Windows 10/11 需要启用WSL 2
- 安装后确认：
  ```powershell
  docker --version
  docker-compose --version
  ```

### 2. 配置Docker资源
在Docker Desktop设置中：
- **CPU**: 至少4核
- **内存**: 至少8GB
- **磁盘**: 至少20GB

---

## 🚀 快速开始

### 方法1：使用docker-compose（推荐）

```bash
# 1. 进入docker目录
cd docker

# 2. 构建并启动容器
docker-compose up -d --build

# 3. 进入容器
docker exec -it miniob bash

# 4. 在容器内编译项目
cd /root/code/miniob  # 或你的代码目录
bash build.sh init
bash build.sh debug --make -j4

# 5. 运行测试
cd build_debug
ctest --output-on-failure

# 6. 运行集成测试
cd /root/code/miniob
python3 test/integration_test/libminiob_test.py -c test/integration_test/conf.ini
```

### 方法2：手动构建（更灵活）

```bash
# 1. 构建镜像
docker build -t miniob:local -f docker/Dockerfile .

# 2. 运行容器（挂载本地代码）
docker run -it --name miniob-test \
  -v D:/code/miniob:/root/miniob \
  -p 10000:22 \
  miniob:local bash

# 3. 在容器内操作（同上）
```

---

## 🔧 完整测试流程

### 步骤1：构建项目

```bash
cd /root/miniob  # 容器内代码目录

# 初始化依赖（仅首次）
bash build.sh init

# 编译Debug版本
bash build.sh debug --make -j4

# 编译Release版本
bash build.sh release --make -j4
```

### 步骤2：单元测试

```bash
cd build_debug
ctest --output-on-failure

# 或只运行特定测试
ctest -R observer_test --verbose
ctest -R common_test --verbose
```

### 步骤3：集成测试（最重要！）

```bash
cd /root/miniob

# 安装Python依赖（仅首次）
apt update && apt install -y python3-pip python3-pymysql python3-psutil

# 运行完整集成测试
cd test/integration_test
bash miniob_test_docker_entry.sh
python3 libminiob_test.py -c conf.ini

# 或运行单个测试
python3 libminiob_test.py -c conf.ini --test-case basic
```

### 步骤4：基础SQL测试

```bash
cd /root/miniob

# 启动observer
./build_debug/bin/observer -f etc/observer.ini &

# 运行SQL测试脚本
python3 test/case/miniob_test.py --test-cases=basic

# 或手动测试
./build_debug/bin/obclient
# 在obclient中执行SQL
```

---

## 🐛 测试我们的Expression功能

### 1. 快速验证

在容器内创建测试SQL：

```bash
cat > /tmp/test_expr.sql << 'EOF'
CREATE TABLE exp_table(id int, col1 int, col2 int);
INSERT INTO exp_table VALUES (1, 5, 3);
INSERT INTO exp_table VALUES (2, 8, 4);
INSERT INTO exp_table VALUES (3, 10, 2);

-- 测试表达式
SELECT * FROM exp_table WHERE col1 + col2 > 10;
SELECT * FROM exp_table WHERE -0 < col1 - col2;
SELECT * FROM exp_table WHERE 5 + col2 < 11;

-- 测试UPDATE with expression
UPDATE exp_table SET col1=100 WHERE id+1=3;
SELECT * FROM exp_table;

-- 测试DELETE with expression
DELETE FROM exp_table WHERE col1 - col2 < 3;
SELECT * FROM exp_table;

DROP TABLE exp_table;
EOF

# 启动observer
cd /root/miniob
./build_debug/bin/observer -f etc/observer.ini &
sleep 2

# 执行测试
./build_debug/bin/obclient < /tmp/test_expr.sql
```

### 2. 详细对比测试

```bash
# 使用integration test框架
cd test/integration_test

# 将我们的test_expression_new.sql放到test_cases目录
cp /root/miniob/test_expression_new.sql test_cases/

# 运行测试
python3 libminiob_test.py -c conf.ini --test-case expression_new
```

---

## 📊 常见问题

### Q1: Docker容器启动失败
```bash
# 查看日志
docker logs miniob

# 重新构建
docker-compose down
docker-compose up -d --build
```

### Q2: 编译失败
```bash
# 清理构建目录
rm -rf build_debug build_release

# 重新初始化
bash build.sh init
bash build.sh debug --make -j4
```

### Q3: 测试失败如何调试
```bash
# 查看详细日志
ctest --verbose --output-on-failure

# 查看observer日志
cat observer.log.*

# 手动运行单个测试
./build_debug/unittest/observer_test
```

### Q4: 如何更新容器内的代码
```bash
# 方法1：在容器内git pull
docker exec -it miniob bash
cd /root/miniob
git pull

# 方法2：使用volume挂载（推荐）
# 在docker-compose.yml中添加：
volumes:
  - D:/code/miniob:/root/miniob
```

---

## 🎯 推荐工作流程

### 每次修改代码后：

```bash
# 1. 在Windows上编辑代码
# 使用VSCode/Cursor等

# 2. 在Docker中编译
docker exec -it miniob bash
cd /root/miniob
bash build.sh debug --make -j4

# 3. 快速测试
cd build_debug
ctest -R expression --verbose  # 只测试expression相关

# 4. 完整测试（push前）
cd /root/miniob
python3 test/integration_test/libminiob_test.py -c test/integration_test/conf.ini

# 5. 如果通过，再push到GitHub
# 如果失败，在容器内调试
```

---

## 💡 高级技巧

### 1. 使用VSCode Remote Container
- 安装"Remote - Containers"插件
- 直接在容器内开发和调试
- 享受完整的IDE功能

### 2. 持久化数据
```yaml
# docker-compose.yml
volumes:
  - ./data:/root/miniob/miniob  # 数据库文件
  - ./build:/root/miniob/build_debug  # 编译缓存
```

### 3. 并行测试
```bash
# 使用多核并行编译
bash build.sh debug --make -j8

# 并行运行测试
ctest -j4
```

### 4. 性能分析
```bash
# 使用valgrind检测内存泄漏
apt install valgrind
valgrind --leak-check=full ./build_debug/bin/observer

# 使用gprof性能分析
bash build.sh debug -DCMAKE_CXX_FLAGS="-pg"
```

---

## 📚 相关资源

- **Docker文档**: https://docs.docker.com/
- **miniob Docker配置**: `docker/README.md`
- **集成测试文档**: `test/integration_test/README.md`
- **CI配置参考**: `.github/workflows/build-test.yml`

---

## ✅ 测试检查清单

在push到GitHub之前，确保：

- [ ] ✅ 编译通过（debug + release）
- [ ] ✅ 单元测试通过（`ctest`）
- [ ] ✅ 集成测试通过（`libminiob_test.py`）
- [ ] ✅ 基础测试通过（`miniob_test.py --test-cases=basic`）
- [ ] ✅ 手动SQL测试通过（expression功能）
- [ ] ✅ 没有内存泄漏（valgrind）
- [ ] ✅ 代码格式正确（`clang-format`）

**只有全部通过，CI才会成功！** 🎉

