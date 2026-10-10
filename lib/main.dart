import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NoteStore.init();
  runApp(const SmartNotesApp());
}

class SmartNotesApp extends StatefulWidget {
  const SmartNotesApp({Key? key}) : super(key: key);
  @override
  State<SmartNotesApp> createState() => _SmartNotesAppState();
}

class _SmartNotesAppState extends State<SmartNotesApp> {
  ThemeMode mode = ThemeMode.light;
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'يوسف؟',
        theme: NotesTheme.light,
        darkTheme: NotesTheme.dark,
        themeMode: mode,
        home: NotesHome(
          onToggleTheme: () => setState(
            () => mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
          ),
        ),
      );
}

class Note {
  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.color,
    required this.updatedAt,
    this.pinned = false,
  });
  final String id;
  String title;
  String body;
  String category;
  int color;
  DateTime updatedAt;
  bool pinned;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category,
        'color': color,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'pinned': pinned,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        category: json['category'] as String? ?? 'Personal',
        color: json['color'] as int? ?? 0,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int? ?? 0),
        pinned: json['pinned'] as bool? ?? false,
      );
}

class NoteStore {
  static late SharedPreferences _prefs;
  static const _key = 'smart_notes_items';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (!_prefs.containsKey(_key)) await save(_demo());
  }

  static List<Note> load() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return <Note>[];
      return (jsonDecode(raw) as List)
          .map((item) => Note.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Note>[];
    }
  }

  static Future<void> save(List<Note> notes) async =>
      _prefs.setString(_key, jsonEncode(notes.map((note) => note.toJson()).toList()));

  static List<Note> _demo() => <Note>[
        Note(
          id: 'welcome',
          title: 'يوسف؟',
          body: 'هذا قالب مذكرة جاهز للتطوير. أضف فكرة، مهمة، أو ملاحظة سريعة ثم صنفها كما تريد.',
          category: 'Ideas',
          color: 1,
          updatedAt: DateTime.now(),
          pinned: true,
        ),
        Note(
          id: 'plan',
          title: 'يوسف؟',
          body: 'مراجعة المهام المهمة وإنهاء العمل العميق قبل المساء.',
          category: 'Work',
          color: 0,
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
}

class NotesHome extends StatefulWidget {
  const NotesHome({Key? key, required this.onToggleTheme}) : super(key: key);
  final VoidCallback onToggleTheme;
  @override
  State<NotesHome> createState() => _NotesHomeState();
}

class _NotesHomeState extends State<NotesHome> {
  List<Note> notes = NoteStore.load();
  String query = '';
  String filter = 'All';

  List<Note> get visible {
    final list = notes.where((note) {
      final matchesText = query.trim().isEmpty ||
          '${note.title} ${note.body}'.toLowerCase().contains(query.toLowerCase());
      final matchesFilter = filter == 'All' ||
          (filter == 'Pinned' ? note.pinned : note.category == filter);
      return matchesText && matchesFilter;
    }).toList();
    list.sort((a, b) => a.pinned == b.pinned
        ? b.updatedAt.compareTo(a.updatedAt)
        : (a.pinned ? -1 : 1));
    return list;
  }

  Future<void> _save(Note note) async {
    final index = notes.indexWhere((item) => item.id == note.id);
    setState(() {
      if (index == -1) {
        notes.add(note);
      } else {
        notes[index] = note;
      }
    });
    await NoteStore.save(notes);
  }

  Future<void> _createOrEdit([Note? note]) async {
    final saved = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => NoteEditor(note: note)),
    );
    if (saved != null) await _save(saved);
  }

  Future<void> _delete(Note note) async {
    setState(() => notes.removeWhere((item) => item.id == note.id));
    await NoteStore.save(notes);
  }

  String _date(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes.clamp(1, 59)} دقيقة';
    }
    if (difference.inHours < 24) return 'منذ ${difference.inHours} ساعة';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مذكرتي',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.dark_mode_outlined),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createOrEdit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'ملاحظة جديدة',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ─── مربع البحث ───
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'ابحث في ملاحظاتك...',
                ),
              ),
            ),

            // ─── شرائح التصفية (✅ مُصلَّحة: بدون <Widget>) ───
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: ['All', 'Pinned', 'Work', 'Personal', 'Ideas']
                    .map((item) {
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(
                        item == 'All'
                            ? 'الكل'
                            : item == 'Pinned'
                                ? 'مثبتة'
                                : item == 'Work'
                                    ? 'عمل'
                                    : item == 'Personal'
                                        ? 'شخصية'
                                        : 'أفكار',
                      ),
                      selected: filter == item,
                      onSelected: (_) => setState(() => filter = item),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ─── العنوان + العدد ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: <Widget>[
                  Text(
                    '${visible.length} ملاحظات',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'محليًا وآمنًا',
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: scheme.primary,
                  ),
                ],
              ),
            ),

            // ─── قائمة الملاحظات ───
            Expanded(
              child: visible.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final note = visible[index];
                        return _noteCard(note, _date(note.updatedAt));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.auto_awesome_mosaic_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد ملاحظات مطابقة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'أنشئ ملاحظة جديدة أو جرّب كلمة بحث أخرى.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _noteCard(Note note, String date) {
    final palette = NoteColor
        .colors[note.color.clamp(0, NoteColor.colors.length - 1).toInt()];
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _delete(note),
      child: Card(
        color: palette.withOpacity(
          Theme.of(context).brightness == Brightness.dark ? .24 : 1,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _createOrEdit(note),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'بدون عنوان' : note.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (note.pinned) const Icon(Icons.push_pin_rounded, size: 18),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  note.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    height: 1.55,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(.72),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.06),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(note.category),
                    ),
                    const Spacer(),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NoteEditor extends StatefulWidget {
  const NoteEditor({Key? key, this.note}) : super(key: key);
  final Note? note;
  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController title;
  late final TextEditingController body;
  late String category;
  late int color;
  late bool pinned;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    title = TextEditingController(text: note?.title ?? '');
    body = TextEditingController(text: note?.body ?? '');
    category = note?.category ?? 'Personal';
    color = note?.color ?? 0;
    pinned = note?.pinned ?? false;
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  void save() {
    if (title.text.trim().isEmpty && body.text.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(
      context,
      Note(
        id: widget.note?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: title.text.trim(),
        body: body.text.trim(),
        category: category,
        color: color,
        updatedAt: DateTime.now(),
        pinned: pinned,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: save,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            widget.note == null ? 'ملاحظة جديدة' : 'تعديل الملاحظة',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: <Widget>[
            IconButton(
              onPressed: () => setState(() => pinned = !pinned),
              icon: Icon(
                pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              ),
            ),
            TextButton(onPressed: save, child: const Text('حفظ')),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            TextField(
              controller: title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              decoration: const InputDecoration(
                hintText: 'العنوان',
                filled: false,
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: body,
              minLines: 14,
              maxLines: null,
              autofocus: widget.note == null,
              style: const TextStyle(fontSize: 17, height: 1.7),
              decoration: const InputDecoration(
                hintText: 'اكتب فكرتك هنا...',
                filled: false,
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 24),
            const Text('التصنيف', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: <String>['Work', 'Personal', 'Ideas'].map((item) {
                return ChoiceChip(
                  label: Text(
                    item == 'Work'
                        ? 'عمل'
                        : item == 'Personal'
                            ? 'شخصية'
                            : 'أفكار',
                  ),
                  selected: category == item,
                  onSelected: (_) => setState(() => category = item),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            const Text('لون الملاحظة', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(
              children: List<Widget>.generate(
                NoteColor.colors.length,
                (index) => GestureDetector(
                  onTap: () => setState(() => color = index),
                  child: Container(
                    margin: const EdgeInsetsDirectional.only(end: 12),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: NoteColor.colors[index],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == index
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}