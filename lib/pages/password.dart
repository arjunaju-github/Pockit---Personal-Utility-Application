import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/password_service.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  double sliderPosition = 0;
  bool wrongShown = false;

  int d1 = 0;
  int d2 = 0;
  int d3 = 0;
  int d4 = 0;

  final controller1 = FixedExtentScrollController(initialItem: 1000);
  final controller2 = FixedExtentScrollController(initialItem: 1000);
  final controller3 = FixedExtentScrollController(initialItem: 1000);
  final controller4 = FixedExtentScrollController(initialItem: 1000);

  Widget numberWheel(
      FixedExtentScrollController controller,
      ValueChanged<int> onSelected,
      ) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 45,
            perspective: 0.003,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              onSelected(index % 10);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final number = index % 10;

                return Center(
                  child: Text(
                    number.toString(),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                );
              },
              childCount: 10000,
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
          ),

          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white70,
                    Colors.white70,
                    Colors.white70,
                    Colors.white10,
                    Colors.white70,
                    Colors.white70,
                  ],
                  stops: [0.0, 0.15, 0.35, 0.65, 0.85, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    controller3.dispose();
    controller4.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/Lock.png', height: 300),
            const Text(
              'Enter master password to access passwords.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(child: numberWheel(controller1, (v) => d1 = v)),
                const SizedBox(width: 8),
                Expanded(child: numberWheel(controller2, (v) => d2 = v)),
                const SizedBox(width: 8),
                Expanded(child: numberWheel(controller3, (v) => d3 = v)),
                const SizedBox(width: 8),
                Expanded(child: numberWheel(controller4, (v) => d4 = v)),
              ],
            ),

            const SizedBox(height: 40),

            LayoutBuilder(
              builder: (context, constraints) {
                double sliderWidth = constraints.maxWidth;
                double knobSize = 60;
                double knobMargin = 5;
                double maxPosition =
                    sliderWidth - knobSize - (knobMargin * 2);

                return Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Center(
                        child: Opacity(
                          opacity: 1 - (sliderPosition / maxPosition),
                          child: const Text(
                            "Slide to Enter",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: sliderPosition,
                        child: GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              sliderPosition += details.delta.dx;

                              if (sliderPosition < 0) sliderPosition = 0;
                              if (sliderPosition > maxPosition) {
                                sliderPosition = maxPosition;
                              }
                            });
                          },

                          onHorizontalDragEnd: (_) async {
                            String entered = "$d1$d2$d3$d4";

                            final userId =
                            await AuthService().getCurrentUserId();
                            if (userId == null) return;

                            bool isValid =
                            await AuthService().verifyMasterPassword(
                                userId, entered);

                            if (!isValid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Wrong combination"),
                                ),
                              );

                              setState(() {
                                sliderPosition = 0;
                              });
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Passwords(),
                              ),
                            ).then((_) {
                              setState(() {
                                sliderPosition = 0;
                                d1 = d2 = d3 = d4 = 0;

                                controller1.jumpToItem(1000);
                                controller2.jumpToItem(1000);
                                controller3.jumpToItem(1000);
                                controller4.jumpToItem(1000);
                              });
                            });
                          },

                          child: Container(
                            width: knobSize,
                            height: knobSize,
                            margin: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.double_arrow,
                              color: Color(0xFF3A3A3A),
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordItem {
  final int? id;
  final String title;
  final String username;
  final String password;
  final String description;

  PasswordItem({
    this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'description': description,
    };
  }

  factory PasswordItem.fromMap(Map<String, dynamic> map) {
    return PasswordItem(
      id: map['id'],
      title: map['title'],
      username: map['username'] ?? '',
      password: map['password'],
      description: map['description'] ?? '',
    );
  }
}

class Passwords extends StatefulWidget {
  const Passwords({super.key});

  @override
  State<Passwords> createState() => _PasswordsState();
}

class _PasswordsState extends State<Passwords> with TickerProviderStateMixin {
  List<PasswordItem> passwords = [];
  int? expandedIndex;
  TextEditingController searchController = TextEditingController();
  List<PasswordItem> filteredPasswords = [];
  bool isSelectionMode = false;
  Set<int> selectedIndexes = {};

  @override
  void initState() {
    super.initState();
    loadPasswords();
  }

  Future<void> loadPasswords() async {
    final data = await PasswordService().getPasswords();

    setState(() {
      passwords = data;
      filteredPasswords = List.from(data);
    });
  }



    void _enterSelectionMode() {
      if (passwords.isEmpty) return;

      setState(() {
        isSelectionMode = true;
        selectedIndexes.clear();
      });
    }

    void _exitSelectionMode() {
      setState(() {
        isSelectionMode = false;
        selectedIndexes.clear();
      });
    }

    void _toggleSelection(int index) {
      setState(() {
        if (selectedIndexes.contains(index)) {
          selectedIndexes.remove(index);
        } else {
          selectedIndexes.add(index);
        }
      });
    }

    void _confirmDelete() {
      if (selectedIndexes.isEmpty) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Delete Passwords"),
          content: Text(
            "Are you sure you want to delete ${selectedIndexes.length} selected password(s)?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                for (int index in selectedIndexes) {
                  final item = passwords[index];

                  if (item.id != null) {
                    await PasswordService().deletePassword(item.id!);
                  }
                }

                await loadPasswords();

                setState(() {
                  isSelectionMode = false;
                  selectedIndexes.clear();
                });

                searchPasswords(searchController.text);

                Navigator.pop(context);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }
  void searchPasswords(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredPasswords = passwords;
      });
      return;
    }
    final results = passwords.where((item) {
      final title = item.title.toLowerCase();
      final username = item.username.toLowerCase();
      final search = query.toLowerCase();

      return title.startsWith(search) || username.startsWith(search);
    }).toList();

    setState(() {
      filteredPasswords = results;
    });
  }

  void showPasswordDetails(PasswordItem item, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                if (item.username.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Username / Email",
                        style: TextStyle(color: Colors.grey),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: item.username),
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Username copied"),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),

                const Text("Password", style: TextStyle(color: Colors.grey)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.password,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: item.password));

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Password copied")),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                if (item.description.isNotEmpty)
                  const Text(
                    "Description",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);

                          final updated = await showDialog(
                            context: context,
                            builder: (_) => AddPasswordDialog(password: item),
                          );

                          if (updated != null) {
                            await PasswordService().updatePassword(updated);
                            await loadPasswords();
                          }
                        },
                        child: const Text(
                          "Edit",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          bool? confirmDelete = await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Delete Password"),
                                content: const Text(
                                  "Are you sure you want to delete this password?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                    child: const Text("Cancel"),
                                  ),

                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete == true) {
                            if (item.id != null) {
                              await PasswordService().deletePassword(item.id!);
                            }

                            await loadPasswords();

                            Navigator.pop(
                              context,
                            );
                          }
                        },
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: isSelectionMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
        )
            : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          isSelectionMode
              ? "${selectedIndexes.length} selected"
              : "My Passwords",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.only(right: 20),
            icon: Icon(
              isSelectionMode ? Icons.delete : Icons.delete_outline,
              color: Colors.black,
            ),
            onPressed: isSelectionMode ? _confirmDelete : _enterSelectionMode,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25,vertical: 5),

        child: Column(
          children: [
            SizedBox(
              height: 45,
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  searchPasswords(value);
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(top: 2),
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
            ),

            const SizedBox(height: 20),

            Expanded(
              child: filteredPasswords.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/password_empty.png',
                          width: 260,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Passwords',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const Text(
                          'You have no passwords added.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: filteredPasswords.length,
                      itemBuilder: (context, index) {
                        final item = filteredPasswords[index];

                        return Column(
                          children: [
                            GestureDetector(
                              onTap: isSelectionMode
                                  ? () => _toggleSelection(index)
                                  : () {
                                setState(() {
                                  if (expandedIndex == index) {
                                    expandedIndex = null;
                                  } else {
                                    expandedIndex = index;
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                padding: const EdgeInsets.all(15),

                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),

                                child: Row(
                                  children: [

                                    if (isSelectionMode)
                                      Checkbox(
                                        value: selectedIndexes.contains(index),
                                        onChanged: (_) => _toggleSelection(index),
                                      ),

                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),

                                    IconButton(
                                      icon: AnimatedRotation(
                                        turns: expandedIndex == index ? 0.5 : 0,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: const Icon(
                                          Icons.keyboard_arrow_down,
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (expandedIndex == index) {
                                            expandedIndex = null;
                                          } else {
                                            expandedIndex = index;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            ClipRect(
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: expandedIndex == index
                                    ? Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                          bottom: 15,
                                        ),
                                        padding: const EdgeInsets.all(20),

                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),

                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (item.username.isNotEmpty) ...[
                                              const Text(
                                                "Username / Email",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),

                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.username,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),

                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.copy,
                                                      size: 20,
                                                    ),
                                                    onPressed: () {
                                                      Clipboard.setData(
                                                        ClipboardData(
                                                          text: item.username,
                                                        ),
                                                      );

                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "Username copied",
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 15),
                                            ],

                                            const Text(
                                              "Password",
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),

                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.password,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),

                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.copy,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    Clipboard.setData(
                                                      ClipboardData(
                                                        text: item.password,
                                                      ),
                                                    );

                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          "Password copied",
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 15),

                                            if (item
                                                .description
                                                .isNotEmpty) ...[
                                              const Text(
                                                "Description",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),

                                              Text(
                                                item.description,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),

                                              const SizedBox(height: 20),
                                            ],

                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      final updated =
                                                          await showDialog(
                                                            context: context,
                                                            builder: (_) =>
                                                                AddPasswordDialog(
                                                                  password:
                                                                      item,
                                                                ),
                                                          );

                                                      if (updated != null) {
                                                        setState(() {
                                                          passwords[index] =
                                                              updated;
                                                        });
                                                      }
                                                    },
                                                    child: const Text(
                                                      "Edit",
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 10),

                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      bool? confirmDelete = await showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          return AlertDialog(
                                                            title: const Text("Delete Password"),
                                                            content: const Text(
                                                              "Are you sure you want to delete this password?",
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.pop(context, false);
                                                                },
                                                                child: const Text("Cancel"),
                                                              ),

                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.pop(context, true);
                                                                },
                                                                child: const Text(
                                                                  "Delete",
                                                                  style: TextStyle(color: Colors.red),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );

                                                      if (confirmDelete == true) {
                                                        setState(() {
                                                          passwords.remove(item);
                                                          expandedIndex = null;
                                                          searchPasswords(searchController.text);
                                                        });
                                                      }
                                                    },
                                                    child: const Text(
                                                      "Delete",
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: GestureDetector(
                onTap: () async {
                  final newPassword = await showDialog(
                    context: context,
                    builder: (_) => const AddPasswordDialog(),
                  );

                  if (newPassword != null) {
                    await PasswordService().insertPassword(newPassword);
                    await loadPasswords();
                  }
                },

                child: SafeArea(
                  child: Container(
                    width: double.infinity,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 51, 33, 33),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Center(
                      child: Text(
                        'Add New',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddPasswordDialog extends StatefulWidget {
  final PasswordItem? password;

  const AddPasswordDialog({super.key, this.password});

  @override
  State<AddPasswordDialog> createState() => _AddPasswordDialogState();
}

class _AddPasswordDialogState extends State<AddPasswordDialog> {
  final titleController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.password != null) {
      titleController.text = widget.password!.title;
      usernameController.text = widget.password!.username;
      passwordController.text = widget.password!.password;
      descriptionController.text = widget.password!.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      child: Padding(
        padding: const EdgeInsets.all(20),

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.password == null ? "Add Password" : "Edit Password",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 15),

              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Title *",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: "Username / Email",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: "Password *",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty ||
                        passwordController.text.isEmpty) {
                      return;
                    }

                    PasswordItem item = PasswordItem(
                      id: widget.password?.id,
                      title: titleController.text,
                      username: usernameController.text,
                      password: passwordController.text,
                      description: descriptionController.text,
                    );

                    Navigator.pop(context, item);
                  },
                  child: const Text("Save"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
