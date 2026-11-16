import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const ProesPdfManager());

class ProesPdfManager extends StatelessWidget {
  const ProesPdfManager({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proes PDF Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB5121B)),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        useMaterial3: true,
      ),
      home: const ArchivePage(),
    );
  }
}

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  Directory? _root;
  List<String> _folders = [];
  String _current = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory('${docs.path}/ProesPDF');
    if (!await root.exists()) await root.create(recursive: true);
    if (!mounted) return;
    setState(() {
      _root = root;
      _loading = false;
    });
    await _refresh();
  }

  Directory get _currentDirectory => Directory(
        _current.isEmpty ? _root!.path : '${_root!.path}/$_current',
      );

  Future<void> _refresh() async {
    if (_root == null) return;
    await _currentDirectory.create(recursive: true);
    final entries = await _currentDirectory.list(followLinks: false).toList();
    if (!mounted) return;
    setState(() {
      _folders = entries
          .where((e) => e is Directory || e.path.toLowerCase().endsWith('.pdf'))
          .map((e) => e.path.split(Platform.pathSeparator).last)
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    });
  }

  Future<void> _addPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result == null || result.files.single.path == null) return;
    final source = File(result.files.single.path!);
    final name = result.files.single.name;
    var target = File('${_currentDirectory.path}/$name');
    var i = 1;
    while (await target.exists()) {
      final dot = name.lastIndexOf('.');
      final base = dot < 0 ? name : name.substring(0, dot);
      target = File('${_currentDirectory.path}/${base}_$i.pdf');
      i++;
    }
    await source.copy(target.path);
    await _refresh();
  }

  Future<void> _newFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni klasör'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Klasör adı'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Oluştur')),
        ],
      ),
    );
    if (name == null || name.isEmpty || name.contains('/') || name.contains('\\')) return;
    await Directory('${_currentDirectory.path}/$name').create(recursive: true);
    await _refresh();
  }

  Future<void> _openFolder(String name) async {
    setState(() => _current = _current.isEmpty ? name : '$_current/$name');
    await _refresh();
  }

  Future<void> _rename(String name) async {
    final controller = TextEditingController(text: name);
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeniden adlandır'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Kaydet')),
        ],
      ),
    );
    if (updated == null || updated.isEmpty || updated.contains('/') || updated.contains('\\')) return;
    final oldPath = '${_currentDirectory.path}/$name';
    final newName = name.toLowerCase().endsWith('.pdf') && !updated.toLowerCase().endsWith('.pdf')
        ? '$updated.pdf'
        : updated;
    await FileSystemEntity.type(oldPath) == FileSystemEntityType.directory
        ? Directory(oldPath).rename('${_currentDirectory.path}/$newName')
        : File(oldPath).rename('${_currentDirectory.path}/$newName');
    await _refresh();
  }

  Future<void> _delete(String name) async {
    final path = '${_currentDirectory.path}/$name';
    if (await FileSystemEntity.type(path) == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    } else {
      await File(path).delete();
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isRoot = _current.isEmpty;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB5121B),
        foregroundColor: Colors.white,
        title: const Text('PROES PDF MANAGER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        leading: isRoot
            ? const Icon(Icons.picture_as_pdf)
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  final parts = _current.split('/');
                  parts.removeLast();
                  setState(() => _current = parts.join('/'));
                  await _refresh();
                },
              ),
        actions: [
          IconButton(tooltip: 'Klasör oluştur', onPressed: _loading ? null : _newFolder, icon: const Icon(Icons.create_new_folder_outlined)),
          IconButton(tooltip: 'PDF ekle', onPressed: _loading ? null : _addPdf, icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(isRoot ? 'Belgelerim' : _current.replaceAll('/', '  /  '),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: _folders.isEmpty
                      ? const Center(child: Text('Henüz dosya veya klasör yok.\n+ düğmesiyle PDF ekleyebilir, klasör oluşturabilirsiniz.', textAlign: TextAlign.center))
                      : ListView.builder(
                          itemCount: _folders.length,
                          itemBuilder: (context, index) {
                            final name = _folders[index];
                            final path = '${_currentDirectory.path}/$name';
                            final folder = FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: Icon(folder ? Icons.folder : Icons.picture_as_pdf,
                                    color: folder ? const Color(0xFFB5121B) : Colors.red),
                                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                onTap: () async {
                                  if (folder) {
                                    await _openFolder(name);
                                  } else {
                                    await OpenFilex.open(path);
                                  }
                                },
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'rename') _rename(name);
                                    if (value == 'delete') _delete(name);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'rename', child: Text('Yeniden adlandır')),
                                    PopupMenuItem(value: 'delete', child: Text('Sil')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFB5121B),
        foregroundColor: Colors.white,
        onPressed: _addPdf,
        icon: const Icon(Icons.upload_file),
        label: const Text('PDF Ekle'),
      ),
    );
  }
}
