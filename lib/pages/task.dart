import 'dart:math';
import 'package:demoapp/pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../services/task_notification_service.dart';
import '../services/task_service.dart';

class Task {
  final int? id;
  final int? userId;
  final String title;
  final String description;
  final String icon;
  final String dueDate;
  final String dueTime;
  final int isDone;

  Task({
    this.id,
    this.userId,
    required this.title,
    required this.description,
    required this.icon,
    required this.dueDate,
    required this.dueTime,
    this.isDone = 0,
  });
  DateTime get deadline {
    try {
      final dateParts = dueDate.split('-');
      final timeParts = dueTime.split(':');

      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  Task copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    String? icon,
    String? dueDate,
    String? dueTime,
    int? isDone,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'icon': icon,
      'dueDate': dueDate,
      'dueTime': dueTime,
      'isDone': isDone,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      icon: map['icon'],
      dueDate: map['dueDate'],
      dueTime: map['dueTime'],
      isDone: map['isDone'],
    );
  }
}

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  List<Task> tasks = [];
  int coins = 0;
  String userName = "";
  bool isGridView = false;
  TextEditingController searchController = TextEditingController();
  List<Task> filteredTasks = [];
  String getRemainingTime(DateTime deadline) {
    Duration difference = deadline.difference(DateTime.now());

    if (difference.isNegative) {
      return "Expired";
    }

    int days = difference.inDays;
    int hours = difference.inHours % 24;
    int minutes = difference.inMinutes % 60;

    if (days > 0) {
      return "${days}d ${hours}h left";
    } else if (hours > 0) {
      return "${hours}h ${minutes}m left";
    } else {
      return "${minutes}m left";
    }
  }

  @override
  void initState() {
    super.initState();
    loadTasks();
    loadUser();
  }

  Future<void> loadUser() async {
    final userId = await AuthService().getCurrentUserId();

    if (userId == null) return;

    final user = await AuthService().getUserById(userId);

    setState(() {
      userName = user?['name'] ?? "User";
      coins = user?['coins'] ?? 0;
    });
  }

  Future<void> loadTasks() async {
    final data = await TaskService().getTasks();

    setState(() {
      tasks = data;
      filteredTasks = data;
    });
  }

  Future<void> _scheduleTaskNotification(Task task) async {
    if (task.id == null) return;

    await TaskNotificationService.instance.scheduleTaskReminder(
      taskId: task.id!,
      title: task.title,
      description: task.description,
      deadline: task.deadline,
    );
  }

  void searchTasks(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredTasks = tasks;
      });
      return;
    }

    final results = tasks.where((task) {
      final title = task.title.toLowerCase();
      final search = query.toLowerCase();

      return title.contains(search);
    }).toList();

    setState(() {
      filteredTasks = results;
    });
  }

  void _showTaskDetails(Task task, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      child: ClipOval(
                        child: Image.asset(
                          task.icon,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      task.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(task.description, textAlign: TextAlign.center),

                    const SizedBox(height: 20),

                    Text(
                      "Deadline:",
                      style: TextStyle(color: Colors.grey[700]),
                    ),

                    Text(
                      "Date - ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}\nTime - ${task.deadline.hour}:${task.deadline.minute}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      getRemainingTime(task.deadline),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);

                              final updatedTask = await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AddTaskPage(task: task),
                              );

                              if (updatedTask != null && task.id != null) {
                                final taskToSave = updatedTask.copyWith(
                                  id: task.id,
                                  userId: task.userId,
                                );

                                await TaskService().updateTask(
                                  task.id!,
                                  taskToSave,
                                );
                                await TaskNotificationService.instance
                                    .cancelTaskReminder(task.id!);
                                await _scheduleTaskNotification(taskToSave);

                                await loadTasks();
                              }
                            },
                            style: ElevatedButton.styleFrom(elevation: 0),
                            child: Text(
                              "Edit",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              int reward = calculateReward(task.deadline);

                              if (task.id != null) {
                                await TaskService().deleteTask(task.id!);
                                await TaskNotificationService.instance
                                    .cancelTaskReminder(task.id!);
                              }

                              await loadTasks();

                              final userId = await AuthService()
                                  .getCurrentUserId();

                              if (userId != null) {
                                int updatedCoins = coins + reward;

                                if (updatedCoins < 0) updatedCoins = 0;

                                await AuthService().updateCoins(
                                  userId,
                                  updatedCoins,
                                );

                                setState(() {
                                  coins = updatedCoins;
                                });
                              }

                              Navigator.pop(context);

                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(
                                    reward >= 0
                                        ? "Task Completed!"
                                        : "Task Failed",
                                  ),
                                  content: Text(
                                    reward >= 0
                                        ? "+$reward coins earned"
                                        : "$reward coins deducted",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(dialogContext);
                                      },
                                      child: const Text("OK"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(elevation: 0),
                            child: const Text(
                              "Completed",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool isSelectionMode = false;
  Set<int> selectedIndexes = {};
  void _exitSelectionMode() {
    setState(() {
      isSelectionMode = false;
      selectedIndexes.clear();
    });
  }

  void _enterSelectionMode() {
    if (tasks.isEmpty) return;

    setState(() {
      isSelectionMode = true;
      selectedIndexes.clear();
    });
  }

  void _confirmDelete() {
    if (selectedIndexes.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Tasks"),
        content: Text(
          "Are you sure you want to delete ${selectedIndexes.length} selected task(s)?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              for (int index in selectedIndexes) {
                final task = tasks[index];
                if (task.id != null) {
                  await TaskService().deleteTask(task.id!);
                  await TaskNotificationService.instance.cancelTaskReminder(
                    task.id!,
                  );
                }
              }

              await loadTasks();

              setState(() {
                isSelectionMode = false;
                selectedIndexes.clear();
              });

              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

  Color getDeadlineColor(DateTime deadline) {
    Duration remaining = deadline.difference(DateTime.now());

    if (remaining.isNegative) {
      return Colors.red;
    }

    if (remaining.inHours < 24) {
      return Colors.red;
    }

    return Colors.black;
  }

  int calculateReward(DateTime deadline) {
    DateTime now = DateTime.now();
    Random random = Random();

    if (now.isAfter(deadline)) {
      if (coins == 0) return 0;

      int penalty = random.nextInt(51) + 100;
      return -penalty;
    }

    Duration remaining = deadline.difference(now);

    int maxReward = 300;
    int minReward = 250;

    int reward = minReward + random.nextInt(maxReward - minReward + 1);

    if (remaining.inHours < 5) {
      reward -= 50;
    }
    if (remaining.inHours < 2) {
      reward -= 80;
    }

    return reward;
  }

  @override
  Widget build(BuildContext context) {
    tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 250),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 250, 250, 250),
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: isSelectionMode
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _exitSelectionMode,
                            icon: const Icon(Icons.close, color: Colors.black),
                          ),

                          Text(
                            "${selectedIndexes.length} selected",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          IconButton(
                            onPressed: _confirmDelete,
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Welcome,",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              IconButton(
                                onPressed: _enterSelectionMode,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.black,
                                ),
                              ),

                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ValuePointPage(coins: coins),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/images/coin.png',
                                        height: 22,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        coins.toString(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tasks", style: TextStyle(fontSize: 22)),

                IconButton(
                  icon: Icon(
                    isGridView ? Icons.view_list : Icons.grid_view_rounded,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      isGridView = !isGridView;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 45,
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  searchTasks(value);
                },
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(top: 1),
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
              child: filteredTasks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/task_empty.png',
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
                      itemCount: filteredTasks.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];

                        return GestureDetector(
                          onTap: () => _showTaskDetails(task, index),
                          onLongPress: () {
                            if (!isSelectionMode) {
                              _enterSelectionMode();
                              _toggleSelection(index);
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.1),
                                      blurRadius: 6,
                                      spreadRadius: -1,
                                      offset: Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.06),
                                      blurRadius: 4,
                                      spreadRadius: -1,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 200),

                                    CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Colors.grey[300],
                                      child: ClipOval(
                                        child: Image.asset(
                                          task.icon,
                                          width: 40,
                                          height: 40,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    Text(
                                      task.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    Expanded(
                                      child: Text(
                                        task.description,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    const SizedBox(height: 5),
                                    Text(
                                      getRemainingTime(task.deadline),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: getDeadlineColor(task.deadline),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (isSelectionMode)
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Checkbox(
                                    value: selectedIndexes.contains(index),
                                    onChanged: (_) => _toggleSelection(index),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];

                        return GestureDetector(
                          onTap: () => _showTaskDetails(task, index),
                          onLongPress: () {
                            if (!isSelectionMode) {
                              _enterSelectionMode();
                              _toggleSelection(index);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.1),
                                  blurRadius: 6,
                                  spreadRadius: -1,
                                  offset: Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.06),
                                  blurRadius: 4,
                                  spreadRadius: -1,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                if (isSelectionMode)
                                  Checkbox(
                                    value: selectedIndexes.contains(index),
                                    onChanged: (_) => _toggleSelection(index),
                                  ),

                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey[200],
                                  child: ClipOval(
                                    child: Image.asset(
                                      task.icon,
                                      width: 50,
                                      height: 50,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 15),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        task.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                Text(
                                  getRemainingTime(task.deadline),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: getDeadlineColor(task.deadline),
                                  ),
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

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 51, 33, 33),
        onPressed: () async {
          final newTask = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AddTaskPage(),
          );

          if (newTask != null) {
            int id = await TaskService().insertTask(newTask);
            await _scheduleTaskNotification(newTask.copyWith(id: id));
            await loadTasks();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class AddTaskPage extends StatefulWidget {
  final Task? task;

  const AddTaskPage({super.key, this.task});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  String selectedIcon = "assets/images/personal.png";
  final List<String> icons = [
    "assets/images/personal.png",
    "assets/images/work.png",
    "assets/images/study.png",
    "assets/images/other.png",
  ];
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  double sliderPosition = 0;

  @override
  void initState() {
    super.initState();

    if (widget.task != null) {
      titleController.text = widget.task!.title;
      descriptionController.text = widget.task!.description;
      selectedIcon = widget.task!.icon;

      selectedDate = widget.task!.deadline;
      selectedTime = TimeOfDay(
        hour: widget.task!.deadline.hour,
        minute: widget.task!.deadline.minute,
      );
    }
  }

  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.task == null ? "Add Task" : "Edit Task",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) {
                            return Container(
                              height: 180,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 15),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: icons.map((icon) {
                                      String label = "";

                                      if (icon.contains("personal"))
                                        label = "Personal";
                                      if (icon.contains("work")) label = "Work";
                                      if (icon.contains("study"))
                                        label = "Study";
                                      if (icon.contains("other"))
                                        label = "Other";

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedIcon = icon;
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              child: ClipOval(
                                                child: Image.asset(
                                                  icon,
                                                  width: 45,
                                                  height: 45,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 6),

                                            Text(
                                              label,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },

                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey.shade200,
                        child: ClipOval(
                          child: Image.asset(
                            selectedIcon,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Select Icon",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text("Task Title"),
              const SizedBox(height: 8),

              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: "Enter task title",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              const Text("Task Description"),
              const SizedBox(height: 8),

              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Enter task description",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              const Text("Due Date"),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: () async {
                  selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade600),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 10),
                      Text(
                        selectedDate == null
                            ? "Select Date"
                            : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text("Due Time"),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: () async {
                  selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade600),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 10),
                      Text(
                        selectedTime == null
                            ? "Select Time"
                            : selectedTime!.format(context),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

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
                              "Slide to Add Task",
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
                                if (sliderPosition > maxPosition)
                                  sliderPosition = maxPosition;
                              });
                            },

                            onHorizontalDragEnd: (_) {
                              if (sliderPosition >= maxPosition - 10) {
                                if (titleController.text.isEmpty ||
                                    (selectedDate == null &&
                                        selectedTime == null)) {
                                  setState(() => sliderPosition = 0);
                                  return;
                                }

                                DateTime now = DateTime.now();
                                DateTime deadline;

                                if (selectedDate != null &&
                                    selectedTime != null) {
                                  deadline = DateTime(
                                    selectedDate!.year,
                                    selectedDate!.month,
                                    selectedDate!.day,
                                    selectedTime!.hour,
                                    selectedTime!.minute,
                                  );
                                } else if (selectedDate != null) {
                                  deadline = DateTime(
                                    selectedDate!.year,
                                    selectedDate!.month,
                                    selectedDate!.day,
                                    0,
                                    0,
                                  );
                                } else {
                                  deadline = DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    selectedTime!.hour,
                                    selectedTime!.minute,
                                  );

                                  if (deadline.isBefore(now)) {
                                    deadline = deadline.add(
                                      const Duration(days: 1),
                                    );
                                  }
                                }

                                Task newTask = Task(
                                  title: titleController.text,
                                  description: descriptionController.text,
                                  icon: selectedIcon,
                                  dueDate:
                                      "${deadline.year}-${deadline.month}-${deadline.day}",
                                  dueTime:
                                      "${deadline.hour}:${deadline.minute}",
                                );

                                Navigator.pop(context, newTask);

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) {
                                    return Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        width: 300,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Lottie.asset(
                                              "assets/lottie/created.json",
                                              repeat: false,
                                              width: 180,
                                              height: 180,
                                            ),

                                            const SizedBox(height: 10),

                                            const Text(
                                              "Task Created!",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            const SizedBox(height: 20),

                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text("Okay"),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              } else {
                                setState(() => sliderPosition = 0);
                              }
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
      ),
    );
  }
}
