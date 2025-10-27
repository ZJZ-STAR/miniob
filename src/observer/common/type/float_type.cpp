/* Copyright (c) 2021 OceanBase and/or its affiliates. All rights reserved.
miniob is licensed under Mulan PSL v2.
You can use this software according to the terms and conditions of the Mulan PSL v2.
You may obtain a copy of Mulan PSL v2 at:
         http://license.coscl.org.cn/MulanPSL2
THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
See the Mulan PSL v2 for more details. */

#include "common/lang/comparator.h"
#include "common/lang/sstream.h"
#include "common/log/log.h"
#include "common/type/float_type.h"
#include "common/value.h"
#include "common/lang/limits.h"
#include "common/value.h"
#include "storage/common/column.h"

int FloatType::compare(const Value &left, const Value &right) const
{
  ASSERT(left.attr_type() == AttrType::FLOATS, "left type is not float");
  
  // 浮点数与浮点数或整数比较
  if (right.attr_type() == AttrType::INTS || right.attr_type() == AttrType::FLOATS) {
    float left_val  = left.get_float();
    float right_val = right.get_float();
    return common::compare_float((void *)&left_val, (void *)&right_val);
  }
  
  // 浮点数与字符串比较：尝试将字符串转换为数字
  if (right.attr_type() == AttrType::CHARS) {
    try {
      const char *str = right.value_.pointer_value_;
      if (str == nullptr) {
        return INT32_MAX;  // 空字符串，无法比较
      }
      
      // 尝试转换为浮点数进行比较
      char *end_ptr;
      double right_num = strtod(str, &end_ptr);
      
      // 检查是否成功转换（至少有一部分被转换）
      if (end_ptr == str) {
        // 完全无法转换，按字典序比较字符串表示
        string left_str = left.to_string();
        return common::compare_string(
            (void *)left_str.c_str(), left_str.length(), (void *)str, right.length_);
      }
      
      double left_num = (double)left.get_float();
      
      if (left_num < right_num) {
        return -1;
      } else if (left_num > right_num) {
        return 1;
      } else {
        return 0;
      }
    } catch (...) {
      // 转换失败，返回未实现
      return INT32_MAX;
    }
  }
  
  // 其他类型不支持
  LOG_WARN("unsupported comparison between float and type %d", right.attr_type());
  return INT32_MAX;
}

int FloatType::compare(const Column &left, const Column &right, int left_idx, int right_idx) const
{
  ASSERT(left.attr_type() == AttrType::FLOATS, "left type is not float");
  ASSERT(right.attr_type() == AttrType::FLOATS, "right type is not float");
  return common::compare_float((void *)&((float*)left.data())[left_idx],
      (void *)&((float*)right.data())[right_idx]);
}

RC FloatType::add(const Value &left, const Value &right, Value &result) const
{
  result.set_float(left.get_float() + right.get_float());
  return RC::SUCCESS;
}
RC FloatType::subtract(const Value &left, const Value &right, Value &result) const
{
  result.set_float(left.get_float() - right.get_float());
  return RC::SUCCESS;
}
RC FloatType::multiply(const Value &left, const Value &right, Value &result) const
{
  result.set_float(left.get_float() * right.get_float());
  return RC::SUCCESS;
}

RC FloatType::divide(const Value &left, const Value &right, Value &result) const
{
  if (right.get_float() > -EPSILON && right.get_float() < EPSILON) {
    // NOTE:
    // 设置为浮点数最大值是不正确的。通常的做法是设置为NULL，但是当前的miniob没有NULL概念，所以这里设置为浮点数最大值。
    result.set_float(numeric_limits<float>::max());
  } else {
    result.set_float(left.get_float() / right.get_float());
  }
  return RC::SUCCESS;
}

RC FloatType::negative(const Value &val, Value &result) const
{
  result.set_float(-val.get_float());
  return RC::SUCCESS;
}

RC FloatType::cast_to(const Value &val, AttrType type, Value &result) const
{
  switch (type) {
  case AttrType::INTS: {
    int int_value = static_cast<int>(val.get_float());
    result.set_int(int_value);
    return RC::SUCCESS;
  }
  case AttrType::CHARS: {
    // 将浮点数转换为字符串
    string str_value;
    RC rc = to_string(val, str_value);
    if (rc == RC::SUCCESS) {
      result.set_string(str_value.c_str());
    }
    return rc;
  }
  default:
    LOG_WARN("unsupported type %d", type);
    return RC::SCHEMA_FIELD_TYPE_MISMATCH;
  }
}

RC FloatType::set_value_from_str(Value &val, const string &data) const
{
  RC                rc = RC::SUCCESS;
  stringstream deserialize_stream;
  deserialize_stream.clear();
  deserialize_stream.str(data);

  float float_value;
  deserialize_stream >> float_value;
  if (!deserialize_stream || !deserialize_stream.eof()) {
    rc = RC::SCHEMA_FIELD_TYPE_MISMATCH;
  } else {
    val.set_float(float_value);
  }
  return rc;
}

RC FloatType::to_string(const Value &val, string &result) const
{
  stringstream ss;
  ss << common::double_to_str(val.value_.float_value_);
  result = ss.str();
  return RC::SUCCESS;
}
