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
#include "common/type/integer_type.h"
#include "common/value.h"
#include "storage/common/column.h"

int IntegerType::compare(const Value &left, const Value &right) const
{
  ASSERT(left.attr_type() == AttrType::INTS, "left type is not integer");
  
  if (right.attr_type() == AttrType::INTS) {
    return common::compare_int((void *)&left.value_.int_value_, (void *)&right.value_.int_value_);
  } else if (right.attr_type() == AttrType::FLOATS) {
    float left_val  = left.get_float();
    float right_val = right.get_float();
    return common::compare_float((void *)&left_val, (void *)&right_val);
  } else if (right.attr_type() == AttrType::CHARS) {
    // 整数与字符串比较：尝试将字符串转换为数字
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
        string left_str = std::to_string(left.get_int());
        return common::compare_string(
            (void *)left_str.c_str(), left_str.length(), (void *)str, right.length_);
      }
      
      double left_num = (double)left.get_int();
      
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
  
  return INT32_MAX;
}

int IntegerType::compare(const Column &left, const Column &right, int left_idx, int right_idx) const
{
  ASSERT(left.attr_type() == AttrType::INTS, "left type is not integer");
  
  // 如果类型不同，返回错误标志（理论上不应该到这里，应该走逐行比较路径）
  if (right.attr_type() != AttrType::INTS && right.attr_type() != AttrType::FLOATS) {
    LOG_WARN("IntegerType::compare(Column) called with incompatible right type: %s", 
             attr_type_to_string(right.attr_type()));
    return INT32_MAX;
  }
  
  // 处理 INTS 和 FLOATS
  if (right.attr_type() == AttrType::INTS) {
    return common::compare_int((void *)&((int*)left.data())[left_idx],
        (void *)&((int*)right.data())[right_idx]);
  } else {
    // right is FLOATS
    float left_val = (float)((int*)left.data())[left_idx];
    float right_val = ((float*)right.data())[right_idx];
    return common::compare_float((void *)&left_val, (void *)&right_val);
  }
}

RC IntegerType::cast_to(const Value &val, AttrType type, Value &result) const
{
  switch (type) {
  case AttrType::FLOATS: {
    float float_value = val.get_int();
    result.set_float(float_value);
    return RC::SUCCESS;
  }
  case AttrType::CHARS: {
    // 将整数转换为字符串
    string str_value = std::to_string(val.get_int());
    result.set_string(str_value.c_str());
    return RC::SUCCESS;
  }
  default:
    LOG_WARN("unsupported type %d", type);
    return RC::SCHEMA_FIELD_TYPE_MISMATCH;
  }
}

RC IntegerType::add(const Value &left, const Value &right, Value &result) const
{
  result.set_int(left.get_int() + right.get_int());
  return RC::SUCCESS;
}

RC IntegerType::subtract(const Value &left, const Value &right, Value &result) const
{
  result.set_int(left.get_int() - right.get_int());
  return RC::SUCCESS;
}

RC IntegerType::multiply(const Value &left, const Value &right, Value &result) const
{
  result.set_int(left.get_int() * right.get_int());
  return RC::SUCCESS;
}

RC IntegerType::negative(const Value &val, Value &result) const
{
  result.set_int(-val.get_int());
  return RC::SUCCESS;
}

RC IntegerType::set_value_from_str(Value &val, const string &data) const
{
  RC                rc = RC::SUCCESS;
  stringstream deserialize_stream;
  deserialize_stream.clear();  // 清理stream的状态，防止多次解析出现异常
  deserialize_stream.str(data);
  int int_value;
  deserialize_stream >> int_value;
  if (!deserialize_stream || !deserialize_stream.eof()) {
    rc = RC::SCHEMA_FIELD_TYPE_MISMATCH;
  } else {
    val.set_int(int_value);
  }
  return rc;
}

RC IntegerType::to_string(const Value &val, string &result) const
{
  stringstream ss;
  ss << val.value_.int_value_;
  result = ss.str();
  return RC::SUCCESS;
}