 
 import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

 IconData getWeatherIcon(String code) {
    switch (code) {
      case '0':
        return Icons.wb_sunny;
      case '1':
        return Icons.beach_access;
      case '2':
        return Icons.wb_cloudy;
      case '3':
      case '4':
        return Icons.cloud;
      default:
        return Icons.wb_cloudy;
    }
  }

// DateTime _parseIssueDate(String issueDate) {
//   return DateTime.parse(issueDate);
// }
  
    String parseIssueDate(String timestamp) {
    try {
      String datePart = timestamp.substring(0, 8);
      String timePart = timestamp.substring(8, 12);
      String formattedString = datePart + "T" + timePart.substring(0, 2) + ":" + timePart.substring(2, 4);
      DateTime dateTime = DateTime.parse(formattedString);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      print('Failed to parse issue date: $e');
      return '';
    }
  }