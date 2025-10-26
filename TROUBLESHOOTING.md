# CI 故障排除指南

## 问题摘要

GitHub Actions CI 失败信息：
- `build / init-ubuntu (push)` - Failed after 6 seconds
- `build / build-macos (push)` - Failed after 17 seconds
- `Deploy mdBook site to Pages / deploy (push)` - Failed after 6 seconds

## 最可能的原因

根据错误发生的时间（6-17 秒），最可能的原因是：

### 1. 网络超时或依赖下载失败

在 `build.sh init` 阶段，需要下载和编译第三方依赖，如果网络不稳定或服务器响应慢，会导致超时。

### 2. 语法文件生成的代码问题

修改了 `yacc_sql.y`，但可能没有正确生成对应的 `.hpp` 和 `.cpp` 文件。

## 故障排除步骤

### 步骤 1: 在本地验证编译

```bash
# 清理之前的构建
rm -rf build_debug build_release

# 重新初始化
bash build.sh init

# 尝试编译 debug 版本
bash build.sh debug --make -j4
```

### 步骤 2: 检查语法文件

如果本地编译成功，但在 CI 中失败，可能是语法文件生成问题。

```bash
# 检查是否有语法文件生成的文件
ls -la src/observer/sql/parser/yacc_sql.hpp
ls -la src/observer/sql/parser/yacc_sql.cpp

# 如果文件存在，检查是否有语法错误
grep -n "error" src/observer/sql/parser/yacc_sql.cpp
```

### 步骤 3: 检查依赖下载

```bash
# 查看依赖是否完整
ls -la deps/3rd/usr/local/lib/
ls -la deps/3rd/usr/local/include/
```

### 步骤 4: 强制重新生成

如果怀疑是生成文件的问题：

```bash
# 删除生成的文件
rm -f src/observer/sql/parser/yacc_sql.hpp
rm -f src/observer/sql/parser/yacc_sql.cpp
rm -f src/observer/sql/parser/lex_sql.cpp

# 重新构建
bash build.sh init
```

## 可能的解决方案

### 方案 1: 重新触发 CI

最简单的方法是在 GitHub Actions 页面点击 "Re-run all jobs"。

### 方案 2: 清理缓存

CI 可能使用了旧的缓存。可以：
1. 修改 `.github/workflows/build-test.yml` 中的缓存键
2. 或者在 GitHub Actions 中手动删除缓存

### 方案 3: 检查语法文件

确保 `yacc_sql.y` 的语法是正确的：

```yacc
where_condition_list:
    /* empty */
    {
      $$ = nullptr;
    }
    | where_condition
    {
      $$ = new vector<unique_ptr<Expression>>;
      $$->emplace_back($1);
    }
    | where_condition AND where_condition_list
    {
      if ($3 != nullptr) {
        $$ = $3;
      } else {
        $$ = new vector<unique_ptr<Expression>>;
      }
      $$->emplace($$->begin(), $1);
    }
    ;
```

### 方案 4: 添加更多调试信息

如果问题持续，可以在工作流中添加更多日志：

```yaml
- name: Debug
  shell: bash
  run: |
    echo "Checking deps..."
    ls -la deps/3rd/usr/local/
    echo "Checking generated files..."
    ls -la src/observer/sql/parser/*.hpp src/observer/sql/parser/*.cpp
```

## 临时解决方案

如果 CI 失败是暂时性的网络问题，可以：

1. **等待并重试**：等待一段时间后重新运行 CI
2. **使用本地构建**：在本地测试后再推送
3. **忽略 CI 失败**：如果代码在本地测试通过

## 验证修复

修复后，应该能够成功运行：

```bash
# 完整的构建和测试流程
bash build.sh init
bash build.sh debug --make -j4
cd build_debug && ctest --output-on-failure
```

## 参考链接

- 仓库地址：https://github.com/ZJZ-STAR/miniob-2025.git
- Actions 页面：https://github.com/ZJZ-STAR/miniob-2025/actions
- 最近的提交：0d5de6a
