import 'dart:convert';

String encodeBase64String(String s) {
  return base64Encode(utf8.encode(s));
}

String decodeBase64String(String s) {
  return utf8.decode(base64Decode(s));
}


class DateTimeUtils {
  static final weekDayNames = <String>["日", "一", "二", "三", "四", "五", "六"];

  static String weekDayName(int day) {
    return weekDayNames[day];
  }

  static int dayOfWeekByName(String day) {
    for (int i = 0; i < weekDayNames.length; i++) {
      if (weekDayNames[i] == day) {
        return i;
      }
    }
    return null;
  }

  static int today() {
    var today = DateTime.now();
    return _gregorianToJulian(today.year, today.month, today.day);
  }

  static int now() {
    var now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  static String durationToString(int minutes) {
    if (minutes == 0) {
      return "0m";
    }
    var h = minutes ~/ 60;
    var m = minutes % 60;
    // If m is 0, omit the minutes part
    return "${h > 0 ? "${h}h" : ""}${m > 0 ? "${m}m" : ""}";
  }

  static String timeToString(int time, {bool padZero = false}) {
    if (time == null) {
      return null;
    }
    var h = time ~/ 60;
    var m = time % 60;
    return padZero
      ? "${h ~/ 10}${h % 10}:${m ~/ 10}${m % 10}"
      : "$h:${m ~/ 10}${m % 10}";
  }

  static String dayToString(int day) {
    if (day == null) {
      return null;
    }
    var gregorian = _julianToGregorian(day);
    var y = gregorian ~/ 10000;
    var m = (gregorian % 10000) ~/ 100;
    var d = gregorian % 100;
    return "$y-$m-$d";
  }

  static String timeToStringRelative(int day, int time) {
    if (day == today()) {
      return timeToString(time);
    }
    if (day == today() - 1) {
      return "昨天 ${timeToString(time)}";
    }
    if (day == today() - 2) {
      return "前天 ${timeToString(time)}";
    }
    return "${dayToString(day)} ${timeToString(time)}";
  }

  static String dayToStringRelative(int day) {
    if (day == today()) {
      return "今天";
    }
    if (day == today() - 1) {
      return "昨天";
    }
    if (day == today() - 2) {
      return "前天";
    }
    return dayToString(day);
  }

  static int dayOfWeek(int day) {
    if (day == null) {
      return null;
    }
    return (day + 1) % 7;
  }

  static int yearMonthDayToInt(int y, int m, int d) {
    if (y == null || m == null || d == null) {
      return null;
    }
    return _gregorianToJulian(y, m, d);
  }

  static int yearMonthDayFromInt(int day) {
    if (day == null) {
      return null;
    }
    return _julianToGregorian(day);
  }

  static DateTime dateTimeFromInt(int day) {
    int ymd = yearMonthDayFromInt(day);
    return DateTime(ymd ~/ 10000, (ymd ~/ 100) % 100, ymd % 100);
  }

  // Refer to http://www.stiltner.org/book/bookcalc.htm for gregorian
  // and julian date
  static int _gregorianToJulian(int y, int m, int d) {
    return (1461 * (y + 4800 + (m - 14) ~/ 12)) ~/ 4 +
        (367 * (m - 2 - 12 * ((m - 14) ~/ 12))) ~/ 12 -
        (3 * ((y + 4900 + (m - 14) ~/ 12) / 100)) ~/ 4 +
        d -
        32075;
  }

  static int _julianToGregorian(int jd) {
    var l = jd + 68569;
    var n = (4 * l) ~/ 146097;
    l = l - (146097 * n + 3) ~/ 4;
    var i = (4000 * (l + 1)) ~/ 1461001;
    l = l - (1461 * i) ~/ 4 + 31;
    var j = (80 * l) ~/ 2447;
    var d = l - (2447 * j) ~/ 80;
    l = j ~/ 11;
    var m = j + 2 - (12 * l);
    var y = 100 * (n - 49) + i + l;
    return y * 10000 + m * 100 + d;
  }
}
