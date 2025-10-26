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

#include "sql/stmt/filter_stmt.h"
#include "common/lang/string.h"
#include "common/log/log.h"
#include "common/sys/rc.h"
#include "sql/expr/expression.h"
#include "sql/parser/expression_binder.h"
#include "storage/db/db.h"
#include "storage/table/table.h"

FilterStmt::~FilterStmt()
{
  for (FilterUnit *unit : filter_units_) {
    delete unit;
  }
  filter_units_.clear();
}

RC FilterStmt::create(Db *db, Table *default_table, unordered_map<string, Table *> *tables,
    const ConditionSqlNode *conditions, int condition_num, FilterStmt *&stmt)
{
  RC rc = RC::SUCCESS;
  stmt  = nullptr;

  FilterStmt *tmp_stmt = new FilterStmt();
  
  // 创建表达式绑定器
  BinderContext binder_context;
  binder_context.add_table(default_table);
  if (tables != nullptr) {
    for (auto &iter : *tables) {
      binder_context.add_table(iter.second);
    }
  }
  ExpressionBinder expression_binder(binder_context);
  
  for (int i = 0; i < condition_num; i++) {
    // 如果条件包含表达式，进行绑定并添加到filter_conditions_
    if (conditions[i].left_expr != nullptr || conditions[i].right_expr != nullptr) {
      unique_ptr<Expression> left_expr(conditions[i].left_expr);
      unique_ptr<Expression> right_expr(conditions[i].right_expr);
      
      // 绑定左表达式
      vector<unique_ptr<Expression>> bound_left_list;
      rc = expression_binder.bind_expression(left_expr, bound_left_list);
      if (rc != RC::SUCCESS || bound_left_list.size() != 1) {
        delete tmp_stmt;
        LOG_WARN("failed to bind left expression. condition index=%d", i);
        return rc != RC::SUCCESS ? rc : RC::INTERNAL;
      }
      
      // 绑定右表达式
      vector<unique_ptr<Expression>> bound_right_list;
      rc = expression_binder.bind_expression(right_expr, bound_right_list);
      if (rc != RC::SUCCESS || bound_right_list.size() != 1) {
        delete tmp_stmt;
        LOG_WARN("failed to bind right expression. condition index=%d", i);
        return rc != RC::SUCCESS ? rc : RC::INTERNAL;
      }
      
      // 创建比较表达式
      unique_ptr<Expression> comparison_expr(new ComparisonExpr(
        conditions[i].comp,
        std::move(bound_left_list[0]),
        std::move(bound_right_list[0])
      ));
      
      tmp_stmt->filter_conditions_.push_back(std::move(comparison_expr));
    } else {
      // 使用旧的FilterUnit方式
      FilterUnit *filter_unit = nullptr;
      rc = create_filter_unit(db, default_table, tables, conditions[i], filter_unit);
      if (rc != RC::SUCCESS) {
        delete tmp_stmt;
        LOG_WARN("failed to create filter unit. condition index=%d", i);
        return rc;
      }
      if (filter_unit != nullptr) {
        tmp_stmt->filter_units_.push_back(filter_unit);
      }
    }
  }

  stmt = tmp_stmt;
  return rc;
}

RC get_table_and_field(Db *db, Table *default_table, unordered_map<string, Table *> *tables,
    const RelAttrSqlNode &attr, Table *&table, const FieldMeta *&field)
{
  if (common::is_blank(attr.relation_name.c_str())) {
    table = default_table;
  } else if (nullptr != tables) {
    auto iter = tables->find(attr.relation_name);
    if (iter != tables->end()) {
      table = iter->second;
    }
  } else {
    table = db->find_table(attr.relation_name.c_str());
  }
  if (nullptr == table) {
    LOG_WARN("No such table: attr.relation_name: %s", attr.relation_name.c_str());
    return RC::SCHEMA_TABLE_NOT_EXIST;
  }

  field = table->table_meta().field(attr.attribute_name.c_str());
  if (nullptr == field) {
    LOG_WARN("no such field in table: table %s, field %s", table->name(), attr.attribute_name.c_str());
    table = nullptr;
    return RC::SCHEMA_FIELD_NOT_EXIST;
  }

  return RC::SUCCESS;
}

RC FilterStmt::create_filter_unit(Db *db, Table *default_table, unordered_map<string, Table *> *tables,
    const ConditionSqlNode &condition, FilterUnit *&filter_unit)
{
  RC rc = RC::SUCCESS;

  CompOp comp = condition.comp;
  if (comp < EQUAL_TO || comp >= NO_OP) {
    LOG_WARN("invalid compare operator : %d", comp);
    return RC::INVALID_ARGUMENT;
  }

  // 如果条件包含表达式，则不创建FilterUnit（由调用者处理）
  if (condition.left_expr != nullptr || condition.right_expr != nullptr) {
    filter_unit = nullptr;
    return RC::SUCCESS;
  }

  filter_unit = new FilterUnit;

  if (condition.left_is_attr) {
    Table           *table = nullptr;
    const FieldMeta *field = nullptr;
    rc                     = get_table_and_field(db, default_table, tables, condition.left_attr, table, field);
    if (rc != RC::SUCCESS) {
      LOG_WARN("cannot find attr");
      return rc;
    }
    FilterObj filter_obj;
    filter_obj.init_attr(Field(table, field));
    filter_unit->set_left(filter_obj);
  } else {
    FilterObj filter_obj;
    filter_obj.init_value(condition.left_value);
    filter_unit->set_left(filter_obj);
  }

  if (condition.right_is_attr) {
    Table           *table = nullptr;
    const FieldMeta *field = nullptr;
    rc                     = get_table_and_field(db, default_table, tables, condition.right_attr, table, field);
    if (rc != RC::SUCCESS) {
      LOG_WARN("cannot find attr");
      return rc;
    }
    FilterObj filter_obj;
    filter_obj.init_attr(Field(table, field));
    filter_unit->set_right(filter_obj);
  } else {
    FilterObj filter_obj;
    filter_obj.init_value(condition.right_value);
    filter_unit->set_right(filter_obj);
  }

  filter_unit->set_comp(comp);

  // 检查两个类型是否能够比较
  return rc;
}
