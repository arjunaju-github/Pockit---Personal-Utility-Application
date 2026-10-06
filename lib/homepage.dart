import 'package:flutter/material.dart';
import 'pages/profile.dart';
import 'pages/notes.dart';
import 'pages/task.dart';
import 'pages/password.dart';

class HomePage extends StatefulWidget {
  final int initialIndex; // 👈 ADD THIS

  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Widget> pages = [TaskPage(), NotesPage(), PasswordPage(), ProfilePage()];
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Exit App"),
            content: const Text("Do you want to exit the app?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes"),
              ),
            ],
          ),
        );

        return shouldExit ?? false;
      },

      child: Scaffold(
        body: pages[_selectedIndex],

        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            selectedLabelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.task_alt_rounded),
                activeIcon: Icon(Icons.task_alt_sharp),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit_note),
                activeIcon: Icon(Icons.edit_note),
                label: 'Notes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.lock_outline),
                activeIcon: Icon(Icons.lock_outline),
                label: 'Passwords',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person_outlined),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
