/* Copyright (c) 2021 OceanBase and/or its affiliates. All rights reserved.
miniob is licensed under Mulan PSL v2.
You can use this software according to the terms and conditions of the Mulan PSL v2.
You may obtain a copy of Mulan PSL v2 at:
         http://license.coscl.org.cn/MulanPSL2
THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
See the Mulan PSL v2 for more details. */

#pragma once

#include "common/type/data_type.h"

/**
 * @brief 日期类型
 * @ingroup DataType
 * @details 日期类型存储为从1970年1月1日开始的天数（int32_t）
 * 支持范围：1900-01-01 到 2100-12-31
 */
class DateType : public DataType
{
public:
  DateType() : DataType(AttrType::DATES) {}
  virtual ~DateType() {}

  int compare(const Value &left, const Value &right) const override;
  int compare(const Column &left, const Column &right, int left_idx, int right_idx) const override;

  RC cast_to(const Value &val, AttrType type, Value &result) const override;

  int cast_cost(AttrType type) override
  {
    if (type == AttrType::DATES) {
      return 0;
    }
    if (type == AttrType::CHARS) {
      return 2;  // DATE 转换到 CHARS 的成本为 2（避免进行字符串比较）
    }
    return INT32_MAX;
  }

  RC set_value_from_str(Value &val, const string &data) const override;

  RC to_string(const Value &val, string &result) const override;

private:
  /**
   * @brief 验证日期字符串的合法性
   * @param date_str 日期字符串，格式为 "YYYY-MM-DD"
   * @return RC::SUCCESS 如果日期合法，否则返回 RC::INVALID_ARGUMENT
   */
  RC validate_date_string(const string &date_str) const;

  /**
   * @brief 将日期字符串转换为天数
   * @param date_str 日期字符串，格式为 "YYYY-MM-DD"
   * @param days 输出的天数
   * @return RC::SUCCESS 如果转换成功，否则返回 RC::INVALID_ARGUMENT
   */
  RC parse_date_string(const string &date_str, int32_t &days) const;

  /**
   * @brief 将天数转换为日期字符串
   * @param days 从1970年1月1日开始的天数
   * @param date_str 输出的日期字符串
   * @return RC::SUCCESS 如果转换成功，否则返回 RC::INVALID_ARGUMENT
   */
  RC format_date_string(int32_t days, string &date_str) const;

  /**
   * @brief 检查是否为闰年
   * @param year 年份
   * @return true 如果是闰年，否则返回 false
   */
  bool is_leap_year(int year) const;

  /**
   * @brief 获取指定年月的天数
   * @param year 年份
   * @param month 月份 (1-12)
   * @return 该月的天数
   */
  int get_days_in_month(int year, int month) const;
};

