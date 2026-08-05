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
// Created by Wangyunlai on 2022/5/22.
//

#include "sql/stmt/update_stmt.h"

#include "common/lang/string.h"
#include "common/log/log.h"
#include "sql/stmt/filter_stmt.h"
#include "storage/db/db.h"
#include "storage/table/table.h"

UpdateStmt::UpdateStmt(Table *table, const FieldMeta *field_meta, const Value &value, FilterStmt *filter_stmt)
    : table_(table), value_(value), field_meta_(field_meta), filter_stmt_(filter_stmt)
{}

UpdateStmt::~UpdateStmt()
{
  delete filter_stmt_;
  filter_stmt_ = nullptr;
}

RC UpdateStmt::create(Db *db, const UpdateSqlNode &update, Stmt *&stmt)
{
  stmt = nullptr;

  //检查数据库和表名
  const char *table_name = update.relation_name.c_str();
  if (nullptr == db || common::is_blank(table_name)) {
    LOG_WARN("invalid argument. db=%p, table_name=%p", db, table_name);
    return RC::INVALID_ARGUMENT;
  }

  //对表做存在性检查并找到表
  Table *table = db->find_table(table_name);
  if (nullptr == table) {
    LOG_WARN("no such table. db=%s, table_name=%s", db->name(), table_name);
    return RC::SCHEMA_TABLE_NOT_EXIST;
  }

  //查找被更新字段
  const FieldMeta *field_meta = table->table_meta().field(update.attribute_name.c_str());
  if (nullptr == field_meta) {
    LOG_WARN("no such field in table. db=%s, table=%s, field name=%s",
        db->name(), table_name, update.attribute_name.c_str());
    return RC::SCHEMA_FIELD_NOT_EXIST;
  }

  //处理更新值的类型
  Value value = update.value;  // 保存一个属于当前 UpdateStmt 的更新值

  // 如果解析出来的值类型与字段类型不同，则尝试转换
  if (field_meta->type() != value.attr_type()) {
    Value converted_value;

    RC rc = Value::cast_to(
        value,
        field_meta->type(),
        converted_value);

    if (rc != RC::SUCCESS) {
      LOG_WARN(
          "failed to cast update value. table=%s, field=%s, "
          "value_type=%d, field_type=%d, rc=%d:%s",
          table_name,
          field_meta->name(),
          static_cast<int>(value.attr_type()),
          static_cast<int>(field_meta->type()),
          rc,
          strrc(rc));

      return rc;
    }

    value = converted_value;
  }

  //创建表映射
  unordered_map<string, Table *> table_map;
  table_map.insert(pair<string, Table *>(string(table_name), table));

  //创建过滤条件语句FilterStmt
  FilterStmt *filter_stmt = nullptr;
  RC          rc          = FilterStmt::create(
      db, table, &table_map, update.conditions.data(), static_cast<int>(update.conditions.size()), filter_stmt);
  if (rc != RC::SUCCESS) {
    LOG_WARN("failed to create filter statement. rc=%d:%s", rc, strrc(rc));
    return rc;
  }

  //创建UpdateStmt
  stmt = new UpdateStmt(table, field_meta, value, filter_stmt);
  return RC::SUCCESS;
}
