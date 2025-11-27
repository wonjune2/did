import 'package:did/screens/history_screen.dart';
import 'package:did/screens/report_screen.dart';
import 'package:did/screens/todo_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 좌측 사이드 바
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.today), label: Text('To-do')),
              NavigationRailDestination(icon: Icon(Icons.summarize), label: Text('주간 보고')),
              NavigationRailDestination(icon: Icon(Icons.history), label: Text('히스토리')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [TodoScreen(), ReportScreen(), HistoryScreen()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String title) {
    return Center(
      child: Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
    );
  }
}
