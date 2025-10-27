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
#include "common/log/log.h"
#include "common/type/char_type.h"
#include "common/value.h"

int CharType::compare(const Value &left, const Value &right) const
{
  ASSERT(left.attr_type() == AttrType::CHARS, "left type is not char");
  
  // 字符串与字符串比较
  if (right.attr_type() == AttrType::CHARS) {
    return common::compare_string(
        (void *)left.value_.pointer_value_, left.length_, (void *)right.value_.pointer_value_, right.length_);
  }
  
  // 字符串与数字比较：尝试将字符串转换为数字
  if (right.attr_type() == AttrType::INTS || right.attr_type() == AttrType::FLOATS) {
    // 尝试将字符串转换为数字进行比较
    try {
      const char *str = left.value_.pointer_value_;
      if (str == nullptr) {
        return INT32_MAX;  // 空字符串，无法比较
      }
      
      // 尝试转换为浮点数进行比较
      char *end_ptr;
      double left_num = strtod(str, &end_ptr);
      
      // 检查是否成功转换（至少有一部分被转换）
      if (end_ptr == str) {
        // 完全无法转换，按字典序比较字符串表示
        string right_str = right.to_string();
        return common::compare_string(
            (void *)str, left.length_, (void *)right_str.c_str(), right_str.length());
      }
      
      double right_num = (right.attr_type() == AttrType::INTS) ? 
                         (double)right.get_int() : (double)right.get_float();
      
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
  LOG_WARN("unsupported comparison between char and type %d", right.attr_type());
  return INT32_MAX;
}

RC CharType::set_value_from_str(Value &val, const string &data) const
{
  val.set_string(data.c_str());
  return RC::SUCCESS;
}

RC CharType::cast_to(const Value &val, AttrType type, Value &result) const
{
  switch (type) {
    case AttrType::DATES: {
      // 将字符串转换为日期类型
      result.set_type(AttrType::DATES);
      return DataType::type_instance(AttrType::DATES)->set_value_from_str(result, val.get_string());
    }
    case AttrType::CHARS: {
      result.set_value(val);
      return RC::SUCCESS;
    }
    case AttrType::INTS: {
      // 将字符串转换为整数
      result.set_type(AttrType::INTS);
      return DataType::type_instance(AttrType::INTS)->set_value_from_str(result, val.get_string());
    }
    case AttrType::FLOATS: {
      // 将字符串转换为浮点数
      result.set_type(AttrType::FLOATS);
      return DataType::type_instance(AttrType::FLOATS)->set_value_from_str(result, val.get_string());
    }
    default: return RC::UNIMPLEMENTED;
  }
  return RC::SUCCESS;
}

int CharType::cast_cost(AttrType type)
{
  if (type == AttrType::CHARS) {
    return 0;
  }
  if (type == AttrType::DATES) {
    return 1;  // 支持从 CHARS 转换到 DATES，成本为 1
  }
  if (type == AttrType::INTS || type == AttrType::FLOATS) {
    return 2;  // 支持从 CHARS 转换到数值类型，成本为 2（可能失败）
  }
  return INT32_MAX;
}

RC CharType::to_string(const Value &val, string &result) const
{
  stringstream ss;
  ss << val.value_.pointer_value_;
  result = ss.str();
  return RC::SUCCESS;
}