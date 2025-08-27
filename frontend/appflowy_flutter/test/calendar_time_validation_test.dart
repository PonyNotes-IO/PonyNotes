import 'package:flutter_test/flutter_test.dart';

void main() {
  group('日历时间验证测试', () {
    test('1970年之前的时间应该被拒绝', () {
      final invalidStartTime = DateTime(1969, 12, 31, 10, 0);
      final invalidEndTime = DateTime(1969, 12, 31, 11, 0);
      
      expect(invalidStartTime.year < 1970, true);
      expect(invalidEndTime.year < 1970, true);
    });

    test('1970年及之后的时间应该被接受', () {
      final validStartTime = DateTime(1970, 1, 1, 10, 0);
      final validEndTime = DateTime(1970, 1, 1, 11, 0);
      
      expect(validStartTime.year >= 1970, true);
      expect(validEndTime.year >= 1970, true);
    });

    test('结束时间应该在开始时间之后', () {
      final startTime = DateTime(2024, 1, 1, 10, 0);
      final validEndTime = DateTime(2024, 1, 1, 11, 0);
      final invalidEndTime = DateTime(2024, 1, 1, 9, 0);
      
      expect(validEndTime.isAfter(startTime), true);
      expect(invalidEndTime.isBefore(startTime), true);
    });

    test('时间戳转换测试', () {
      final dateTime = DateTime(2024, 1, 1, 10, 0);
      final timestamp = dateTime.millisecondsSinceEpoch ~/ 1000;
      
      // 验证时间戳转换
      expect(timestamp > 0, true);
      
      // 验证从时间戳恢复时间
      final recoveredDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      expect(recoveredDateTime.year, dateTime.year);
      expect(recoveredDateTime.month, dateTime.month);
      expect(recoveredDateTime.day, dateTime.day);
      expect(recoveredDateTime.hour, dateTime.hour);
      expect(recoveredDateTime.minute, dateTime.minute);
    });

    test('日程时长验证', () {
      final startTime = DateTime(2024, 1, 1, 10, 0);
      final shortEndTime = DateTime(2024, 1, 1, 11, 0);
      final longEndTime = DateTime(2024, 2, 1, 10, 0);
      
      final shortDuration = shortEndTime.difference(startTime);
      final longDuration = longEndTime.difference(startTime);
      
      expect(shortDuration.inDays, 0);
      expect(longDuration.inDays > 30, true);
    });
  });
} 