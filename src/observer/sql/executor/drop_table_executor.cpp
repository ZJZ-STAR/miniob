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

#include "sql/executor/drop_table_executor.h"

#include "common/log/log.h"
#include "event/session_event.h"
#include "event/sql_event.h"
#include "session/session.h"
#include "sql/stmt/drop_table_stmt.h"
#include "storage/db/db.h"

RC DropTableExecutor::execute(SQLStageEvent *sql_event)
{
  // 检查参数有效性
  if (sql_event == nullptr) {
    LOG_ERROR("DropTableExecutor::execute: sql_event is null");
    return RC::INVALID_ARGUMENT;
  }

  Stmt         *stmt          = sql_event->stmt();
  SessionEvent *session_event = sql_event->session_event();
  Session      *session       = session_event ? session_event->session() : nullptr;
  SqlResult    *sql_result    = session_event ? session_event->sql_result() : nullptr;

  // 验证所有必要的对象是否有效
  if (stmt == nullptr || session_event == nullptr || session == nullptr || sql_result == nullptr) {
    LOG_ERROR("DropTableExecutor::execute: invalid parameters");
    return RC::INVALID_ARGUMENT;
  }

  // 确保是正确类型的语句
  ASSERT(stmt->type() == StmtType::DROP_TABLE, 
         "DropTableExecutor can only execute DROP_TABLE statements");

  DropTableStmt *drop_table_stmt = static_cast<DropTableStmt *>(stmt);
  const char    *table_name      = drop_table_stmt->table_name().c_str();

  // 获取当前数据库
  Db *db = session->get_current_db();
  if (db == nullptr) {
    LOG_ERROR("DropTableExecutor::execute: no database selected");
    sql_result->set_return_code(RC::SCHEMA_DB_NOT_OPENED);
    sql_result->set_state_string("No database selected");
    return RC::SCHEMA_DB_NOT_OPENED;
  }

  // 执行删除表操作
  RC rc = db->drop_table(table_name);
  
  // 设置返回码和状态信息
  sql_result->set_return_code(rc);
  
  if (rc == RC::SUCCESS) {
    // 成功时不需要设置错误消息
    LOG_INFO("Successfully dropped table %s", table_name);
  } else {
    // 根据返回的错误码设置适当的错误信息
    LOG_WARN("Failed to drop table %s: rc=%s", table_name, strrc(rc));
    
    switch (rc) {
      case RC::SCHEMA_TABLE_NOT_EXIST:
        sql_result->set_state_string("Table not exists");
        break;
      case RC::INVALID_ARGUMENT:
        sql_result->set_state_string("Invalid table name");
        break;
      case RC::FILE_REMOVE:
      case RC::IOERR_OPEN:
        sql_result->set_state_string("File operation failed");
        break;
      default:
        sql_result->set_state_string("Drop table failed");
        break;
    }
  }

  return rc;
}