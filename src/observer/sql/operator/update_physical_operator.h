/* Copyright (c) 2021 OceanBase and/or its affiliates. All rights reserved.
miniob is licensed under Mulan PSL v2.
You can obtain a copy of the Mulan PSL v2 at:
         http://license.coscl.org.cn/MulanPSL2
THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.
*/

#pragma once

#include "sql/operator/physical_operator.h"

class FieldMeta;
class Table;
class Trx;

/**
 * @brief 物理算子，更新记录
 *
 * UPDATE 的输入子算子产生待更新的行。打开算子时先收集这些行，关闭
 * 输入扫描后再逐条更新，避免更新索引或记录页的过程中继续使用扫描器。
 */
class UpdatePhysicalOperator : public PhysicalOperator
{
public:
  UpdatePhysicalOperator(Table *table, const FieldMeta *field_meta, const Value &value)
      : table_(table), field_meta_(field_meta), value_(value)
  {}

  ~UpdatePhysicalOperator() override = default;

  PhysicalOperatorType type() const override { return PhysicalOperatorType::UPDATE; }
  OpType get_op_type() const override { return OpType::UPDATE; }

  RC open(Trx *trx) override;
  RC next() override;
  RC close() override;

  Tuple *current_tuple() override { return nullptr; }

private:
  Table             *table_      = nullptr;
  const FieldMeta   *field_meta_ = nullptr;
  Value              value_;
  Trx               *trx_        = nullptr;
  vector<Record>     records_;
};
