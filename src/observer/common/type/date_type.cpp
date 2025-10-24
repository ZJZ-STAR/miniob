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

  int32_t days;
  rc = parse_date_string(data, days);
  if (rc != RC::SUCCESS) {
    return rc;
  }

  val.set_int(days);
  return RC::SUCCESS;
}

RC DateType::to_string(const Value &val, string &result) const
{
  int32_t days = val.get_int();
  RC rc = format_date_string(days, result);
  if (rc != RC::SUCCESS) {
    return rc;
  }
  return RC::SUCCESS;
}

RC DateType::validate_date_string(const string &date_str) const
{
  // 使用正则表达式验证日期格式 YYYY-MM-DD 或 YYYY-M-D（月份和日期可以是1-2位数字）
  std::regex date_regex(R"(^\d{4}-\d{1,2}-\d{1,2}$)");
  if (!std::regex_match(date_str, date_regex)) {
    LOG_WARN("Invalid date format: %s, expected YYYY-MM-DD or YYYY-M-D", date_str.c_str());
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

  // 检查年份范围 (1900-2100)
  if (year < 1900 || year > 2100) {
    LOG_WARN("Year out of range: %d, expected 1900-2100", year);
    return RC::INVALID_ARGUMENT;
  }

  // 检查月份范围 (1-12)
  if (month < 1 || month > 12) {
    LOG_WARN("Month out of range: %d, expected 1-12", month);
    return RC::INVALID_ARGUMENT;
  }

  // 检查日期范围
  int days_in_month = get_days_in_month(year, month);
  if (day < 1 || day > days_in_month) {
    LOG_WARN("Day out of range: %d, expected 1-%d for %d-%02d", day, days_in_month, year, month);
    return RC::INVALID_ARGUMENT;
  }

  return RC::SUCCESS;
}

RC DateType::parse_date_string(const string &date_str, int32_t &days) const
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

  // 计算从1970年1月1日开始的天数
  // 1970年1月1日作为基准点 (day 0)
  int total_days = 0;

  // 处理 year >= 1970 的情况
  if (year >= 1970) {
    // 计算年份贡献的天数
    for (int y = 1970; y < year; y++) {
      total_days += is_leap_year(y) ? 366 : 365;
    }

    // 计算月份贡献的天数
    for (int m = 1; m < month; m++) {
      total_days += get_days_in_month(year, m);
    }

    // 加上当前月的天数
    total_days += day - 1; // 减1因为1月1日是第0天
  } else {
    // 处理 year < 1970 的情况，向前计算（结果为负数）
    // 从1969年开始倒退
    for (int y = 1969; y >= year; y--) {
      if (y == year) {
        // 当前年份，只计算到指定日期
        // 先计算到年底的天数，然后减去
        int days_to_end = 0;
        for (int m = month + 1; m <= 12; m++) {
          days_to_end += get_days_in_month(year, m);
        }
        days_to_end += get_days_in_month(year, month) - day + 1;
        total_days -= days_to_end;
      } else {
        // 完整的年份
        total_days -= (is_leap_year(y) ? 366 : 365);
      }
    }
  }

  days = total_days;
  return RC::SUCCESS;
}

RC DateType::format_date_string(int32_t days, string &date_str) const
{
  int year = 1970;
  int month = 1;
  int day = 1;

  if (days >= 0) {
    // 从1970年1月1日开始计算
    int remaining_days = days;

    // 计算年份
    while (remaining_days >= (is_leap_year(year) ? 366 : 365)) {
      remaining_days -= is_leap_year(year) ? 366 : 365;
      year++;
    }

    // 计算月份
    while (remaining_days >= get_days_in_month(year, month)) {
      remaining_days -= get_days_in_month(year, month);
      month++;
    }

    // 计算日期
    day = remaining_days + 1;
  } else {
    // 处理负数天数（1970年之前的日期）
    int remaining_days = -days; // 转换为正数处理
    year = 1969;

    // 向前倒退计算年份
    while (remaining_days > (is_leap_year(year) ? 366 : 365)) {
      remaining_days -= is_leap_year(year) ? 366 : 365;
      year--;
    }

    // 计算月份和日期
    // remaining_days 表示从年初开始倒数的天数
    int days_in_year = is_leap_year(year) ? 366 : 365;
    int days_from_start = days_in_year - remaining_days;

    // 从1月1日开始计算
    month = 1;
    while (days_from_start >= get_days_in_month(year, month)) {
      days_from_start -= get_days_in_month(year, month);
      month++;
    }
    day = days_from_start + 1;
  }

  // 格式化输出
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

