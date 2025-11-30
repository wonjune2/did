import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class DidCalendar extends StatefulWidget {
  const DidCalendar({super.key});

  @override
  State<DidCalendar> createState() => _DidCalendarState();
}

class _DidCalendarState extends State<DidCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const calendarHeaderHeight = 60.0;
        const calendarMaxRowHeight = 52.0;

        final availableHeight = constraints.maxHeight - calendarHeaderHeight;
        final rowHeight = availableHeight / 7;

        final calendarRowHeight = math
            .min(rowHeight, calendarMaxRowHeight)
            .floorToDouble();

        return TableCalendar(
          locale: 'ko_KR',
          focusedDay: _focusedDay,
          firstDay: DateTime.utc(2000, 01, 01),
          lastDay: DateTime.utc(2100, 12, 31),
          daysOfWeekHeight: calendarRowHeight,
          rowHeight: calendarRowHeight,
          calendarStyle: const CalendarStyle(
            defaultTextStyle: TextStyle(fontSize: 15),
            weekendTextStyle: TextStyle(fontSize: 15, color: Colors.redAccent),
          ),
          headerStyle: const HeaderStyle(formatButtonVisible: false),

          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },

          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
        );
      },
    );
  }
}
