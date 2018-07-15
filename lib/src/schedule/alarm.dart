import 'package:hue_dart/src/schedule/schedule.dart';
import 'package:intl/intl.dart';

class Alarm extends Schedule {

  /// days on which the alarm applies in a bitmask; 0MTWTFSS. Weekdays is 01111100 = 124. Tuesdays is 00100000 = 32
  int weekDays;

  /// end date/time for time interval alarms
  DateTime endDate;

  Alarm();

  Alarm.withSchedule(Schedule schedule) : super.withSchedule(schedule) {
    _parseAlarm();
  }

  void _parseAlarm() {
    if (new RegExp(Schedule.RANDOM_RECURRING_TIME_ALARM).hasMatch(time)) {
      _parseRandomRecurringTimeAlarm();
    } else if (new RegExp(Schedule.RECURRING_ALARM).hasMatch(time)) {
      _parseRecurringAlarm();
    } else if (new RegExp(Schedule.RANDOMIZED_TIME_ALARM).hasMatch(time)) {
      _parseRandomizedTimeAlarm();
    } else if (new RegExp(Schedule.ABSOLUTE_TIME_ALARM).hasMatch(time)) {
      _parseAbsoluteTimeAlarm();
    } else if (new RegExp(Schedule.timeIntervalAlarm).hasMatch(time)) {
      _parseTimeIntervalAlarm();
    }
  }

  void _parseAbsoluteTimeAlarm() {
    date = new DateFormat("yyyy-MM-dd'T'HH:m:s").parse(time);
  }

  void _parseRandomizedTimeAlarm() {
    String dateValue = time.substring(0, time.indexOf(Schedule.RANDOM_TIME_DIVIDER));
    String randomValue = time.substring(time.indexOf(Schedule.RANDOM_TIME_DIVIDER) + 1, time.length);
    date = new DateFormat("yyyy-MM-dd'T'HH:m:s").parse(dateValue);
    randomTime = new DateFormat("HH:m:s").parse(randomValue);
  }

  void _parseRecurringAlarm() {
    weekDays = int.parse(time.substring(1, time.indexOf("/")));
    date = new DateFormat("W${weekDays}'/T'HH:m:s").parse(time);
  }

  void _parseRandomRecurringTimeAlarm() {
    String dateValue = time.substring(0, time.indexOf(Schedule.RANDOM_TIME_DIVIDER));
    String randomValue = time.substring(time.indexOf(Schedule.RANDOM_TIME_DIVIDER) + 1, time.length);
    weekDays = int.parse(time.substring(1, time.indexOf("/")));
    date = new DateFormat("W${weekDays}'/T'HH:m:s").parse(dateValue);
    randomTime = new DateFormat("HH:m:s").parse(randomValue);
  }

  void _parseTimeIntervalAlarm() {
    String startTime = time.substring(0, time.indexOf('/T'));
    String endTime = time.substring(time.indexOf('/T'));
    date = new DateFormat("'T'HH:m:s").parse(startTime);
    endDate = new DateFormat("'/T'HH:m:s").parse(endTime);
  }

  String getFormattedTime() {
    if (isRecurringAlarm()) {
      return getRecurringTimeFormat();
    } else {
      return getDefaultTimeFormat();
    }
  }

  bool isRecurringAlarm() {
    return weekDays > 0;
  }

  String getRecurringTimeFormat() {
    String formattedTime = new DateFormat(Schedule.TIME_PATTERN).format(DateTime.now());
    return "W${weekDays}/T${formattedTime}";
  }

  String getDefaultTimeFormat() {
    String formattedDate = new DateFormat(Schedule.DATE_PATTERN).format(DateTime.now());
    String formattedTime = new DateFormat(Schedule.TIME_PATTERN).format(DateTime.now());
    return '${formattedDate}${Schedule.TIME_DIVIDER}${formattedTime}';
  }
}
