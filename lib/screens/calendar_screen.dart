import 'package:did/widgets/did_calendar.dart';
import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '휴가 달력',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '총 휴가',
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                          Text(
                            '8 일',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '사용 휴가',
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                          Text(
                            '8 일',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '남은 휴가',
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                          Text(
                            '8 일',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Expanded(
          flex: 4,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: DidCalendar(),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
