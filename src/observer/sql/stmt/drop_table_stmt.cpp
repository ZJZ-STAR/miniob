/* Copyright (c) 2021 OceanBase and/or its affiliates. All rights reserved.
miniob is licensed under Mulan PSL v2.
You can use this software according to the terms and conditions of the Mulan PSL v2.
You may obtain a copy of Mulan PSL v2 at:
         http://license.coscl.org.cn/MulanPSL2
THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
See the Mulan PSL v2 for more details. */

//
// Created by Wangyunlai on 2023/6/13.
//

// #include "common/log/log.h"
// #include "common/types.h"
// #include "sql/stmt/drop_table_stmt.h"
// #include "event/sql_debug.h"

// RC DropTableStmt::create(Db *db, const DropTableSqlNode &drop_table, Stmt *&stmt)
// {
//   stmt = new DropTableStmt(drop_table.relation_name);
//   return RC::SUCCESS;
// }

#include "common/log/log.h"
#include "common/types.h"
#include "sql/stmt/drop_table_stmt.h"
#include "event/sql_debug.h"
#include "storage/db/db.h"  // 引入Db和Table的头文件
#include "storage/table/table.h"

RC DropTableStmt::create(Db *db, const DropTableSqlNode &drop_table, Stmt *&stmt)
{
  // 1. 校验输入参数合法性
  if (db == nullptr) {
    LOG_ERROR("DropTableStmt::create: db is null (invalid argument)");
    return RC::INVALID_ARGUMENT;  // 数据库指针为空，返回参数错误
  }

  const std::string &table_name = drop_table.relation_name;
  if (table_name.empty()) {
    LOG_ERROR("DropTableStmt::create: table name is empty (invalid argument)");
    return RC::INVALID_ARGUMENT;  // 表名为空，返回参数错误
  }

  // 2. 检查表是否存在，但允许删除不存在的表（符合SQL标准）
  Table *table = db->find_table(table_name.c_str());
  if (table == nullptr) {
    LOG_WARN("DropTableStmt::create: table %s not exists, but allowing drop operation", table_name.c_str());
    // 不返回错误，允许删除不存在的表
  }

  // 3. 所有校验通过，创建DropTableStmt对象
  stmt = new DropTableStmt(table_name);
  LOG_DEBUG("DropTableStmt::create: success, table name=%s", table_name.c_str());
  return RC::SUCCESS;
}
