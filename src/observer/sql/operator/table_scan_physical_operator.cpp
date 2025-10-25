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
// Created by WangYunlai on 2021/6/9.
//

#include "sql/operator/table_scan_physical_operator.h"
#include "event/sql_debug.h"
#include "storage/table/table.h"

using namespace std;

RC TableScanPhysicalOperator::open(Trx *trx)
{
  RC rc = table_->get_record_scanner(record_scanner_, trx, mode_);
  if (rc == RC::SUCCESS) {
    tuple_.set_schema(table_, table_->table_meta().field_metas());
  }
  trx_ = trx;
  return rc;
}

RC TableScanPhysicalOperator::next()
{
  RC rc = RC::SUCCESS;

  bool filter_result = false;
  while (OB_SUCC(rc = record_scanner_->next(current_record_))) {
    LOG_TRACE("got a record. rid=%s", current_record_.rid().to_string().c_str());
    
    tuple_.set_record(&current_record_);
    rc = filter(tuple_, filter_result);
    if (rc != RC::SUCCESS) {
      LOG_TRACE("record filtered failed=%s", strrc(rc));
      return rc;
    }

    if (filter_result) {
      sql_debug("get a tuple: %s", tuple_.to_string().c_str());
      break;
    } else {
      sql_debug("a tuple is filtered: %s", tuple_.to_string().c_str());
    }
  }
  return rc;
}

RC TableScanPhysicalOperator::close() {
  RC rc = RC::SUCCESS;
  if (record_scanner_ != nullptr) {
    rc = record_scanner_->close_scan();
    if (rc != RC::SUCCESS) {
      LOG_WARN("failed to close record scanner");
    }
    delete record_scanner_;
    record_scanner_ = nullptr;
  }
  return rc;

}

Tuple *TableScanPhysicalOperator::current_tuple()
{
  tuple_.set_record(&current_record_);
  return &tuple_;
}

string TableScanPhysicalOperator::param() const { return table_->name(); }

void TableScanPhysicalOperator::set_predicates(vector<unique_ptr<Expression>> &&exprs)
{
  predicates_ = std::move(exprs);
}

RC TableScanPhysicalOperator::filter(RowTuple &tuple, bool &result)
{
  RC    rc = RC::SUCCESS;
  Value value;
  
  // 如果只有一个谓词，直接评估
  if (predicates_.size() == 1) {
    rc = predicates_[0]->get_value(tuple, value);
    if (rc != RC::SUCCESS) {
      return rc;
    }
    result = value.get_boolean();
    return rc;
  }
  
  // 如果有多个谓词，使用AND逻辑：所有谓词都必须为true
  result = true; // 初始化为true
  for (unique_ptr<Expression> &expr : predicates_) {
    rc = expr->get_value(tuple, value);
    if (rc != RC::SUCCESS) {
      return rc;
    }

    bool tmp_result = value.get_boolean();
    if (!tmp_result) {
      result = false; // 任何一个谓词为false，整个结果为false
      return rc; // 可以立即返回false
    }
  }

  // 所有谓词都为true，结果为true
  result = true;
  return rc;
}
