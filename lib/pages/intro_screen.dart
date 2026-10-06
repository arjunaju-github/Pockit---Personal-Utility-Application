import 'package:flutter/material.dart';
import 'package:demoapp/authscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;

  final List<Map<String, String>> data = [
    {
      "image": "assets/images/tasks-intro.png",
      "title": "Stay organized and \nin control",
      "desc": "Manage your daily tasks\nand never miss a deadline.",
    },
    {
      "image": "assets/images/notes-intro.png",
      "title": "Capture ideas instantly",
      "desc": "Write down thoughts and\naccess them anytime.",
    },
    {
      "image": "assets/images/password-intro.png",
      "title": "Secure your passwords",
      "desc": "Access your credentials\nquickly and securely.",
    },
  ];

  void nextPage() async {
    if (currentPage < data.length - 1) {
      _controller.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // ✅ SAVE onboarding completed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seenOnboarding', true);

      // ✅ GO TO AUTH
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    }
  }

  void skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// SCROLLABLE CONTENT
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: data.length,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// IMAGE
                      Image.asset(data[index]["image"]!, height: 350),
                      const SizedBox(height: 40),

                      /// TITLE
                      Text(
                        data[index]["title"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      /// DESCRIPTION
                      Text(
                        data[index]["desc"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            /// DOTS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                data.length,
                (dotIndex) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: currentPage == dotIndex ? 12 : 8,
                  height: currentPage == dotIndex ? 12 : 8,
                  decoration: BoxDecoration(
                    color: currentPage == dotIndex ? Colors.black : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            /// BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  AuthPage(),
                          transitionDuration: Duration(milliseconds: 600),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return Stack(
                                  children: [
                                    child, // next page
                                    FadeTransition(
                                      opacity: Tween(
                                        begin: 1.0,
                                        end: 0.0,
                                      ).animate(animation),
                                      child: Container(color: Colors.white),
                                    ),
                                  ],
                                );
                              },
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: const Text(
                        "SKIP",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 21,
                      ),
                    ),
                    onPressed: nextPage,
                    child: Text(
                      currentPage == data.length - 1 ? "START" : "NEXT",
                      style: const TextStyle(color: Colors.white),
                    ),
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
