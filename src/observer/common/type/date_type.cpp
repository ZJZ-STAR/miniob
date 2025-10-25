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
#include "common/type/date_type.h"
#include "common/value.h"
#include "storage/common/column.h"
#include <regex>
#include <sstream>
#include <iomanip>

int DateType::compare(const Value &left, const Value &right) const
{
  ASSERT(left.attr_type() == AttrType::DATES, "left type is not date");
  
  // 如果右侧也是日期类型，直接比较
  if (right.attr_type() == AttrType::DATES) {
    return common::compare_int((void *)&left.value_.int_value_, (void *)&right.value_.int_value_);
  }
  
  // 如果右侧是字符串，尝试将其转换为日期后再比较
  if (right.attr_type() == AttrType::CHARS) {
    Value right_date;
    right_date.set_type(AttrType::DATES);
    RC rc = set_value_from_str(right_date, right.get_string());
    if (rc != RC::SUCCESS) {
      LOG_WARN("failed to convert string to date: %s", right.get_string().c_str());
      return INT32_MAX;  // 转换失败，返回未实现的比较
    }
    return common::compare_int((void *)&left.value_.int_value_, (void *)&right_date.value_.int_value_);
  }
  
  // 其他类型不支持
  LOG_WARN("unsupported comparison between date and type %d", right.attr_type());
  return INT32_MAX;
}

int DateType::compare(const Column &left, const Column &right, int left_idx, int right_idx) const
{
  ASSERT(left.attr_type() == AttrType::DATES, "left type is not date");
  ASSERT(right.attr_type() == AttrType::DATES, "right type is not date");
  return common::compare_int((void *)&((int*)left.data())[left_idx],
      (void *)&((int*)right.data())[right_idx]);
}

RC DateType::cast_to(const Value &val, AttrType type, Value &result) const
{
  switch (type) {
  case AttrType::DATES: {
    result.set_int(val.get_int());
    result.set_type(AttrType::DATES);
    return RC::SUCCESS;
  }
  case AttrType::CHARS: {
    // 将日期转换为字符串
    string date_str;
    RC rc = to_string(val, date_str);
    if (rc != RC::SUCCESS) {
      return rc;
    }
    result.set_string(date_str.c_str());
    return RC::SUCCESS;
  }
  default:
    LOG_WARN("unsupported cast from dates to %s", attr_type_to_string(type));
    return RC::UNSUPPORTED;
  }
}

RC DateType::set_value_from_str(Value &val, const string &data) const
{
  RC rc = validate_date_string(data);
  if (rc != RC::SUCCESS) {
    return rc;
  }

  int32_t date_int;
  rc = parse_date_string(data, date_int);
  if (rc != RC::SUCCESS) {
    return rc;
  }

  val.set_int(date_int);
  val.set_type(AttrType::DATES);
  return RC::SUCCESS;
}

RC DateType::to_string(const Value &val, string &result) const
{
  int32_t date_int = val.get_int();
  RC rc = format_date_string(date_int, result);
  if (rc != RC::SUCCESS) {
    return rc;
  }
  return RC::SUCCESS;
}

RC DateType::validate_date_string(const string &date_str) const
{
  // 使用正则表达式验证日期格式 YYYY-MM-DD
  std::regex date_pattern(R"(^\d{4}-\d{1,2}-\d{1,2}$)");
  if (!std::regex_match(date_str, date_pattern)) {
    LOG_WARN("invalid date format: %s", date_str.c_str());
    return RC::INVALID_ARGUMENT;
  }

  // 解析年月日
  std::istringstream iss(date_str);
  string year_str, month_str, day_str;
  std::getline(iss, year_str, '-');
  std::getline(iss, month_str, '-');
  std::getline(iss, day_str);

  int year = std::stoi(year_str);
  int month = std::stoi(month_str);
  int day = std::stoi(day_str);

  // 检查日期合法性
  if (year < 1900 || year > 2100) {
    LOG_WARN("year out of range: %d", year);
    return RC::INVALID_ARGUMENT;
  }

  if (month < 1 || month > 12) {
    LOG_WARN("month out of range: %d", month);
    return RC::INVALID_ARGUMENT;
  }

  if (day < 1 || day > get_days_in_month(year, month)) {
    LOG_WARN("day out of range: %d for month %d in year %d", day, month, year);
    return RC::INVALID_ARGUMENT;
  }

  return RC::SUCCESS;
}

RC DateType::parse_date_string(const string &date_str, int32_t &date_int) const
{
  // 解析年月日
  std::istringstream iss(date_str);
  string year_str, month_str, day_str;
  std::getline(iss, year_str, '-');
  std::getline(iss, month_str, '-');
  std::getline(iss, day_str);

  int year = std::stoi(year_str);
  int month = std::stoi(month_str);
  int day = std::stoi(day_str);

  // 转换为YYYYMMDD格式
  date_int = year * 10000 + month * 100 + day;
  return RC::SUCCESS;
}

RC DateType::format_date_string(int32_t date_int, string &date_str) const
{
  int year = date_int / 10000;
  int month = (date_int % 10000) / 100;
  int day = date_int % 100;

  // 格式化输出，确保月份和日期是两位数
  std::ostringstream oss;
  oss << std::setfill('0') << std::setw(4) << year << "-"
      << std::setw(2) << month << "-"
      << std::setw(2) << day;
  
  date_str = oss.str();
  return RC::SUCCESS;
}

bool DateType::is_leap_year(int year) const
{
  return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

int DateType::get_days_in_month(int year, int month) const
{
  static const int days_in_month[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
  
  if (month == 2 && is_leap_year(year)) {
    return 29;
  }
  
  return days_in_month[month - 1];
}