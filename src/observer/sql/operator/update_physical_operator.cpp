/* Copyright (c) 2021 OceanBase and/or its affiliates. All rights reserved.
miniob is licensed under Mulan PSL v2.
You can obtain a copy of the License at:
         http://license.coscl.org.cn/MulanPSL2
*/

#include "sql/operator/update_physical_operator.h"

#include "common/log/log.h"
#include "sql/expr/tuple.h"
#include "storage/field/field_meta.h"
#include "storage/record/record.h"
#include "storage/table/table.h"
#include "storage/trx/trx.h"

RC UpdatePhysicalOperator::open(Trx *trx)
{
  records_.clear();
  trx_ = trx;

  if (table_ == nullptr || field_meta_ == nullptr || trx_ == nullptr) {
    LOG_WARN("invalid arguments for update operator");
    return RC::INVALID_ARGUMENT;
  }

  if (children_.empty()) {
    return RC::SUCCESS;
  }

  unique_ptr<PhysicalOperator> &child = children_[0];
  RC rc = child->open(trx);
  if (rc != RC::SUCCESS) {
    LOG_WARN("failed to open child operator for update: %s", strrc(rc));
    return rc;
  }

  // The record returned by a scan may point directly into a buffer-pool page.
  // Make an owning copy before closing the child scanner or changing indexes.
  while (OB_SUCC(rc = child->next())) {
    Tuple *tuple = child->current_tuple();
    if (tuple == nullptr) {
      LOG_WARN("update child did not produce a row tuple");
      child->close();
      return RC::INTERNAL;
    }

    RowTuple *row_tuple = static_cast<RowTuple *>(tuple);
    Record   &source_record = row_tuple->record();

    Record record;
    rc = record.copy_data(source_record.data(), source_record.len());
    if (rc != RC::SUCCESS) {
      child->close();
      return rc;
    }
    record.set_rid(source_record.rid());
    records_.emplace_back(std::move(record));
  }

  if (rc != RC::RECORD_EOF) {
    child->close();
    LOG_WARN("failed to scan records for update: %s", strrc(rc));
    return rc;
  }

  rc = child->close();
  if (rc != RC::SUCCESS) {
    return rc;
  }

  // Do not update while the input scanner is active. This is important when
  // the SET column is also the indexed/filtered column.
  for (Record &old_record : records_) {
    Record new_record;
    rc = new_record.copy_data(old_record.data(), old_record.len());
    if (rc != RC::SUCCESS) {
      return rc;
    }
    new_record.set_rid(old_record.rid());

    const int field_offset = field_meta_->offset();
    const int field_len = field_meta_->len();
    if (field_offset < 0 || field_len < 0 || field_offset + field_len > new_record.len()) {
      LOG_WARN("invalid update field range. offset=%d, length=%d, record length=%d",
          field_offset, field_len, new_record.len());
      return RC::INVALID_ARGUMENT;
    }

    // Clear the fixed-width field first. This preserves the normal INSERT
    // representation for shorter CHAR values (zero-filled trailing bytes).
    rc = new_record.reset_filed(field_offset, field_len);
    if (rc != RC::SUCCESS) {
      return rc;
    }

    const int copy_len = value_.length() < field_len ? value_.length() : field_len;
    if (copy_len > 0) {
      rc = new_record.set_field(field_offset, copy_len, value_.data());
      if (rc != RC::SUCCESS) {
        return rc;
      }
    }

    rc = trx_->update_record(table_, old_record, new_record);
    if (rc != RC::SUCCESS) {
      LOG_WARN("failed to update record. table=%s, rid=%s, rc=%s",
          table_->name(), old_record.rid().to_string().c_str(), strrc(rc));
      return rc;
    }
  }

  return RC::SUCCESS;
}

RC UpdatePhysicalOperator::next()
{
  return RC::RECORD_EOF;
}

RC UpdatePhysicalOperator::close()
{
  records_.clear();
  trx_ = nullptr;
  return RC::SUCCESS;
}
