import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String collegeName = 'Kallam Haranadha Reddy Institute of Technology';
const Color navy = Color(0xFF123C69);

void main() => runApp(const NoticeBoardApp());

class Notice {
  final String title;
  final String category;
  final String message;
  final String date;

  Notice({
    required this.title,
    required this.category,
    required this.message,
    required this.date,
  });

  Map<String, String> toJson() => {
        'title': title,
        'category': category,
        'message': message,
        'date': date,
      };

  factory Notice.fromJson(Map<String, dynamic> j) => Notice(
        title: j['title'] as String,
        category: j['category'] as String,
        message: j['message'] as String,
        date: j['date'] as String,
      );
}

String todayString() {
  final d = DateTime.now();
  return '${d.day}/${d.month}/${d.year}';
}

List<Notice> defaultNotices() => [
      Notice(
        title: 'Semester Examination',
        category: 'Examination',
        message: 'Semester examinations will start soon.',
        date: todayString(),
      ),
      Notice(
        title: 'Technical Workshop',
        category: 'Events',
        message: 'A technical workshop will be conducted for students.',
        date: todayString(),
      ),
    ];

class NoticeBoardApp extends StatelessWidget {
  const NoticeBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'College Notice Board',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: navy),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<String> categories = [
    'General',
    'Examination',
    'Events',
    'Holiday',
  ];

  List<Notice> notices = defaultNotices();
  String category = categories.first;
  String query = '';

  final titleCtrl = TextEditingController();
  final messageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('notices');
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      final loaded = list
          .map((e) => Notice.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (!mounted) return;
      setState(() => notices = loaded);
    } catch (_) {
      // Corrupted or unavailable storage: keep the default notices.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notices',
        jsonEncode(notices.map((n) => n.toJson()).toList()),
      );
    } catch (_) {
      // Storage unavailable: notices stay in memory only.
    }
  }

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        ),
      );
  }

  void _addNotice() {
    final title = titleCtrl.text.trim();
    final message = messageCtrl.text.trim();

    if (title.isEmpty || message.isEmpty) {
      _snack('Please enter all details!', error: true);
      return;
    }

    setState(() {
      notices.insert(
        0,
        Notice(
          title: title,
          category: category,
          message: message,
          date: todayString(),
        ),
      );
    });
    _save();

    titleCtrl.clear();
    messageCtrl.clear();
    FocusScope.of(context).unfocus();
    _snack('Notice published successfully!');
  }

  Future<void> _deleteNotice(Notice notice) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete notice?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => notices.remove(notice));
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final filtered = notices
        .where((n) =>
            n.title.toLowerCase().contains(q) ||
            n.category.toLowerCase().contains(q) ||
            n.message.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            // Header
            Container(
              color: navy,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: const Column(
                children: [
                  Text(
                    collegeName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'STUDENT NOTICE BOARD APP',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'All College Updates in One Place',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📢 Latest Announcements',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search notices...',
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No notices found.'),
                    ),

                  for (final n in filtered)
                    Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Chip(
                              label: Text(n.category),
                              backgroundColor: const Color(0xFFDBEAFE),
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(height: 6),
                            Text(n.message),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Date: ${n.date}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _deleteNotice(n),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Admin section
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin - Add Notice',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: titleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Notice Title',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: categories
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => category = v);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: messageCtrl,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Enter notice details',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: navy,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _addNotice,
                              child: const Text('Publish Notice'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              color: navy,
              padding: const EdgeInsets.all(16),
              child: const Column(
                children: [
                  Text(
                    '© 2026 $collegeName',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'College Notice Board App',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}