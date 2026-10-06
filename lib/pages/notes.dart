import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import '../io_operations/note_io_service.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermission() async {
  await Permission.storage.request();
}

String noteContentAsPlainText(dynamic content) {
  final value = (content ?? "").toString();

  try {
    final decoded = jsonDecode(value);
    if (decoded is List) {
      return quill.Document.fromJson(decoded).toPlainText().trimRight();
    }
  } catch (_) {
    // Existing notes are stored as plain text, so failed JSON parsing is fine.
  }

  return value;
}

quill.Document noteContentAsDocument(dynamic content) {
  final value = (content ?? "").toString();

  try {
    final decoded = jsonDecode(value);
    if (decoded is List) {
      return quill.Document.fromJson(decoded);
    }
  } catch (_) {
    // Fall through to plain-text import for older notes.
  }

  final document = quill.Document();
  if (value.isNotEmpty) {
    document.insert(0, value);
  }
  return document;
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> notes = [];
  bool isGridView = true;
  bool isSelectionMode = false;
  Set<int> selectedIds = {};
  TextEditingController searchController = TextEditingController();

  int? userId;
  bool isExportMode = false;
  List<Map<String, dynamic>> filteredNotes = [];
  final NoteIOService ioService = NoteIOService();
  final NoteService noteService = NoteService();
  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    userId = await AuthService().getCurrentUserId();
    if (userId != null) {
      _loadNotes();
    }
  }

  Future<void> _loadNotes() async {
    if (userId == null) return;

    final data = await noteService.getNotes(userId!);

    setState(() {
      notes = data;
      filteredNotes = data;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void searchNotes(String query) {
    final searchText = query.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredNotes = notes;
      });
    } else {
      setState(() {
        filteredNotes = notes.where((note) {
          final title = (note["title"] ?? "").toLowerCase();
          final content = noteContentAsPlainText(note["content"]).toLowerCase();

          return title.contains(searchText) || content.contains(searchText);
        }).toList();
      });
    }
  }

  void _goToAddNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddNotePage()),
    );

    if (result != null) {
      await noteService.insertNote({
        "userId": userId,
        "title": result["title"],
        "content": result["content"],
        "createdAt": DateTime.now().toString(),
      });

      _loadNotes();
    }
  }

  void _editNote(Map<String, dynamic> note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddNotePage(note: note)),
    );

    if (result != null) {
      await noteService.updateNote(note["id"], {
        "title": result["title"],
        "content": result["content"],
        "createdAt": DateTime.now().toString(),
      });

      _loadNotes();
    }
  }

  Future<String?> _askFileName() async {
    TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter file name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "e.g. my_notes"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    if (selectedIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Notes"),
        content: Text("Delete ${selectedIds.length} selected note(s)?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              for (final id in selectedIds) {
                await noteService.deleteNote(id);
              }

              await _loadNotes();

              if (!mounted) return;

              setState(() {
                isSelectionMode = false;
                selectedIds.clear();
              });

              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(int id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode() {
    setState(() {
      isSelectionMode = true;
      selectedIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      isSelectionMode = false;
      isExportMode = false;
      selectedIds.clear();
    });
  }

  Future<void> _exportSelected() async {
    await requestStoragePermission();
    if (!mounted) return;

    final selectedNotes = filteredNotes
        .where((note) => selectedIds.contains(note["id"]))
        .toList();

    if (selectedNotes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No notes selected")));
      return;
    }

    final fileName = await _askFileName();

    if (!mounted) return;
    if (fileName == null || fileName.isEmpty) return;

    final path = await ioService.exportAsText(selectedNotes, fileName);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Saved to: $path")));

    setState(() {
      isSelectionMode = false;
      isExportMode = false;
      selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  isSelectionMode
                      ? IconButton(
                          onPressed: _exitSelectionMode,
                          icon: const Icon(Icons.close),
                        )
                      : const Text(
                          'Notes',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  Row(
                    children: [
                      if (!isSelectionMode)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isGridView = !isGridView;
                            });
                          },
                          icon: Icon(
                            isGridView
                                ? Icons.view_list
                                : Icons.grid_view_rounded,
                          ),
                        ),
                      IconButton(
                        onPressed: isSelectionMode
                            ? () {
                                if (isExportMode) {
                                  _exportSelected();
                                } else {
                                  _confirmDelete();
                                }
                              }
                            : _enterSelectionMode,
                        icon: Icon(
                          isSelectionMode
                              ? (isExportMode ? Icons.upload : Icons.delete)
                              : Icons.delete_outline,
                        ),
                      ),
                      if (!isSelectionMode)
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            final messenger = ScaffoldMessenger.of(context);

                            if (value == "import") {
                              await requestStoragePermission();
                              if (!mounted) return;

                              final imported = await ioService.importFromText();
                              if (!mounted) return;

                              if (imported.isEmpty) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "No file selected or empty file",
                                    ),
                                  ),
                                );
                                return;
                              }

                              for (var note in imported) {
                                await noteService.insertNote({
                                  "userId": userId,
                                  "title": note["title"] ?? "",
                                  "content": note["content"] ?? "",
                                  "createdAt": (note["createdAt"] ?? "").isEmpty
                                      ? DateTime.now().toString()
                                      : note["createdAt"],
                                });
                              }

                              _loadNotes();
                            }

                            if (value == "export") {
                              setState(() {
                                isSelectionMode = true;
                                isExportMode = true;
                                selectedIds.clear();
                              });
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: "import",
                              child: Text("Import Notes"),
                            ),
                            const PopupMenuItem(
                              value: "export",
                              child: Text("Export Notes"),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (!isSelectionMode)
                GestureDetector(
                  onTap: _goToAddNote,
                  child: Container(
                    width: double.infinity,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 51, 33, 33),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Center(
                      child: Text(
                        'Create +',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              TextField(
                controller: searchController,
                onChanged: searchNotes,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(top: 1),
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: notes.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/notes_empty.png',
                              width: 260,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Tasks',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const Text(
                              'You have no tasks created.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : isGridView
                    ? GridView.builder(
                        itemCount: filteredNotes.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];

                          return Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: GestureDetector(
                                  onTap: isSelectionMode
                                      ? () => _toggleSelection(note["id"])
                                      : () => _editNote(note),
                                  onLongPress: () {
                                    if (!isSelectionMode) {
                                      _enterSelectionMode();
                                    }
                                    _toggleSelection(note["id"]);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade200,
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (note["title"] ?? "").isEmpty
                                              ? "Untitled"
                                              : note["title"],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          noteContentAsPlainText(
                                            note["content"],
                                          ),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              if (isSelectionMode)
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Checkbox(
                                    value: selectedIds.contains(note["id"]),
                                    onChanged: (_) =>
                                        _toggleSelection(note["id"]),
                                  ),
                                ),
                            ],
                          );
                        },
                      )
                    : ListView.builder(
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];

                          return GestureDetector(
                            onTap: isSelectionMode
                                ? () => _toggleSelection(note["id"])
                                : () => _editNote(note),

                            onLongPress: () {
                              if (!isSelectionMode) {
                                _enterSelectionMode();
                              }
                              _toggleSelection(note["id"]);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note["createdAt"] != null
                                        ? DateFormat(
                                            'dd MMM yyyy, HH:mm',
                                          ).format(
                                            DateTime.parse(note["createdAt"]),
                                          )
                                        : "",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    (note["title"] ?? "").isEmpty
                                        ? "Untitled"
                                        : note["title"],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    noteContentAsPlainText(note["content"]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddNotePage extends StatefulWidget {
  final Map<String, dynamic>? note;

  const AddNotePage({super.key, this.note});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final TextEditingController titleController = TextEditingController();
  late final quill.QuillController contentController;
  final FocusNode contentFocusNode = FocusNode();
  final ScrollController contentScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    contentController = quill.QuillController(
      document: noteContentAsDocument(widget.note?["content"]),
      selection: const TextSelection.collapsed(offset: 0),
    );
    contentController.addListener(_refreshToolbar);

    if (widget.note != null) {
      titleController.text = widget.note!["title"] ?? "";
    }
  }

  void _refreshToolbar() {
    if (mounted) {
      setState(() {});
      setState(() {});
    }
  }

  void _saveNote() {
    Navigator.pop(context, {
      "title": titleController.text,
      "content": jsonEncode(contentController.document.toDelta().toJson()),
    });
  }

  @override
  void dispose() {
    contentController.removeListener(_refreshToolbar);
    contentController.dispose();
    contentFocusNode.dispose();
    contentScrollController.dispose();
    titleController.dispose();
    super.dispose();
  }

  bool _isFormatActive(quill.Attribute attribute) {
    final activeAttribute = contentController
        .getSelectionStyle()
        .attributes[attribute.key];

    if (activeAttribute == null) {
      return false;
    }

    return attribute.key == quill.Attribute.list.key
        ? activeAttribute.value == attribute.value
        : true;
  }

  void _toggleFormat(quill.Attribute attribute) {
    final isActive = _isFormatActive(attribute);

    contentController.formatSelection(
      isActive ? quill.Attribute.clone(attribute, null) : attribute,
    );
    contentFocusNode.requestFocus();
  }

  Widget _formatButton({
    required IconData icon,
    required String tooltip,
    required quill.Attribute attribute,
  }) {
    final isActive = _isFormatActive(attribute);
    final primary = Theme.of(context).colorScheme.primary;

    return IconButton(
      tooltip: tooltip,
      onPressed: () => _toggleFormat(attribute),
      icon: Icon(icon),
      color: isActive ? primary : Colors.black87,
      style: IconButton.styleFrom(
        backgroundColor: isActive ? primary.withValues(alpha: 0.10) : null,
        minimumSize: const Size(42, 42),
      ),
    );
  }

  Widget _formattingBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            _formatButton(
              icon: Icons.format_bold,
              tooltip: "Bold",
              attribute: quill.Attribute.bold,
            ),
            _formatButton(
              icon: Icons.format_italic,
              tooltip: "Italic",
              attribute: quill.Attribute.italic,
            ),
            _formatButton(
              icon: Icons.format_underlined,
              tooltip: "Underline",
              attribute: quill.Attribute.underline,
            ),
            const SizedBox(width: 8),
            _formatButton(
              icon: Icons.format_list_bulleted,
              tooltip: "Bullets",
              attribute: quill.Attribute.ul,
            ),
            _formatButton(
              icon: Icons.format_list_numbered,
              tooltip: "Numbered list",
              attribute: quill.Attribute.ol,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'EEEE, MMMM d • HH:mm',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(top: false, child: _formattingBar()),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  IconButton(
                    onPressed: _saveNote,
                    icon: const Icon(Icons.check),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Title",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: quill.QuillEditor.basic(
                        controller: contentController,
                        focusNode: contentFocusNode,
                        scrollController: contentScrollController,
                        config: quill.QuillEditorConfig(
                          placeholder: "Start writing...",
                          padding: EdgeInsets.zero,
                          expands: true,
                          customStyles: quill.DefaultStyles(
                            paragraph: quill.DefaultTextBlockStyle(
                              const TextStyle(
                                fontSize: 18,
                                height: 1.8,
                                color: Colors.black87, // line spacing
                              ),
                              const quill.HorizontalSpacing(0, 0),
                              const quill.VerticalSpacing(0, 0),
                              const quill.VerticalSpacing(0, 0),
                              null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
