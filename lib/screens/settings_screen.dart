import 'package:did/main.dart';
import 'package:did/services/settings_service.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dailyHeaderController = TextEditingController();
  final _dailyFooterController = TextEditingController();
  final _weeklyHeaderController = TextEditingController();
  final _weeklyFooterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = SettingsService();
    _dailyHeaderController.text = settings.dailyHeader;
    _dailyFooterController.text = settings.dailyFooter;
    _weeklyHeaderController.text = settings.weeklyHeader;
    _weeklyFooterController.text = settings.weeklyFooter;
  }

  Future<void> _saveSettings() async {
    final settings = SettingsService();
    await settings.setDailyHeader(_dailyHeaderController.text);
    await settings.setDailyFooter(_dailyFooterController.text);
    await settings.setWeeklyHeader(_weeklyHeaderController.text);
    await settings.setWeeklyFooter(_weeklyFooterController.text);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('설정이 저장되었습니다.')));
    }
  }

  @override
  void dispose() {
    _dailyHeaderController.dispose();
    _dailyFooterController.dispose();
    _weeklyHeaderController.dispose();
    _weeklyFooterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        actions: [
          IconButton(onPressed: _saveSettings, icon: const Icon(Icons.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('일일 업무 보고 포맷'),
          const SizedBox(height: 8),
          TextField(
            controller: _dailyHeaderController,
            decoration: const InputDecoration(
              labelText: '선행문',
              border: OutlineInputBorder(),
              helperText: '예: 안녕하세요. ',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dailyFooterController,
            decoration: const InputDecoration(
              labelText: '후행문',
              border: OutlineInputBorder(),
              helperText: '예: 진행합니다.',
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('주간 업무 보고 포맷'),
          const SizedBox(height: 8),
          TextField(
            controller: _weeklyHeaderController,
            decoration: const InputDecoration(
              labelText: '선행문',
              border: OutlineInputBorder(),
              helperText: '예: [주간 업무 보고]',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weeklyFooterController,
            decoration: const InputDecoration(
              labelText: '후행문',
              border: OutlineInputBorder(),
              helperText: '예: 이상입니다.',
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('프로젝트 관리'),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: db.watchAllProjects(), // 활성화된 프로젝트만 표시
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final projects = snapshot.data!;
              if (projects.isEmpty) {
                return const Text('등록된 프로젝트가 없습니다.');
              }
              return Column(
                children: projects.map((project) {
                  return ListTile(
                    title: Text(project.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProject(project.id),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProject(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('프로젝트 삭제'),
          content: const Text('정말로 이 프로젝트를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await db.deleteProject(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로젝트가 삭제되었습니다.')));
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
