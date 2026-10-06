import 'package:demoapp/utils/security.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demoapp/authscreen.dart';
import '../homepage.dart';
import '../main.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import '../services/password_service.dart';
import '../services/task_service.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:scratcher/scratcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "Name";
  String email = "emailId";
  String imagePath = "assets/images/male.jpg";
  int coins = 0;
  int? userId;
  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    userId = await AuthService().getCurrentUserId();

    if (userId == null) return;

    final user = await ProfileService().getUser(userId!);

    if (user != null) {
      setState(() {
        name = user['name'] ?? "";
        email = user['email'] ?? "";
        imagePath = user['profileImage'] ?? "assets/images/male.jpg";
        coins = user['coins'] ?? 0;
      });
    }
  }

  void showThemeBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose Theme",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text("Light Theme"),
                onTap: () {
                  MyApp.of(context)?.setLightTheme();
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text("Dark Theme (Work-In-Progress)"),
                onTap: () {
                  MyApp.of(context)?.setDarkTheme();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showAboutBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                "About App",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),

              Text(
                "This application was developed to help users manage tasks, passwords, and personal data securely.\n\nDeveloped by: The Creator\nVersion: 1.0",
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(name: name, imagePath: imagePath),
      ),
    );

    if (result != null && userId != null) {
      await ProfileService().updateUser(userId!, {
        'name': result['name'],
        'profileImage': result['image'],
      });

      loadUser();
    }
  }

  void logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('isLoggedIn');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "My profile",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  GestureDetector(
                    onTap: editProfile,
                    child: CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: const Icon(
                        Icons.edit,
                        color: Color.fromARGB(255, 51, 33, 33),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              CircleAvatar(radius: 60, backgroundImage: AssetImage(imagePath)),
              const SizedBox(height: 15),
              Text(
                name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Text(
                "$email",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 30),

              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ValuePointPage(coins: coins),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 35,
                      vertical: 35,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: AssetImage('assets/images/token_bg.jpg'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your Value Points",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w100,
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "$coins points",
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w500,
                                  ),
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
              const SizedBox(height: 20),
              GestureDetector(
                onTap: showAboutBottomSheet,
                child: buildMenuTile(
                  Icons.insert_comment,
                  "About",
                  "About the application",
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => Account()),
                  );
                },
                child: buildMenuTile(
                  Icons.person,
                  "Account Settings",
                  "Edit your account",
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChangeMasterPassword()),
                  );
                },
                child: buildMenuTile(
                  Icons.password,
                  "Change Password",
                  "Change your master password",
                ),
              ),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Log Out"),
                        content: const Text(
                          "Are you sure you want to log out?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              logout(context);
                            },
                            child: const Text("Log Out"),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: buildMenuTile(
                  Icons.exit_to_app,
                  "Log Out",
                  "Log out of your account.",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMenuTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}

class ValuePointPage extends StatefulWidget {
  final int coins;

  const ValuePointPage({Key? key, required this.coins}) : super(key: key);

  @override
  State<ValuePointPage> createState() => _ValuePointPageState();
}

class _ValuePointPageState extends State<ValuePointPage> {
  late int coins;

  List<Map<String, String>> rewards = [];
  final Random random = Random();
  final List<Color> scratchColors = [
    Colors.grey,
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.brown,
  ];
  final List<Map<String, String>> couponList = [
    {"brand": "Amazon", "offer": "10% OFF"},
    {"brand": "Amazon", "offer": "₹200 OFF"},
    {"brand": "Myntra", "offer": "25% OFF"},
    {"brand": "Swiggy", "offer": "Free Delivery"},
    {"brand": "Zomato", "offer": "30% OFF"},
    {"brand": "Flipkart", "offer": "₹150 OFF"},
    {"brand": "Ajio", "offer": "20% OFF"},
    {"brand": "Uber", "offer": "₹100 Ride OFF"},
    {"brand": "Dominos", "offer": "Buy 1 Get 1"},
    {"brand": "Pizza Hut", "offer": "40% OFF"},
    {"brand": "Nykaa", "offer": "15% OFF"},
    {"brand": "BookMyShow", "offer": "₹120 OFF"},
  ];
  int coupon_price = 1500;

  @override
  void initState() {
    super.initState();
    coins = widget.coins;
  }

  String generateCouponCode(String brand) {
    String short = brand.substring(0, min(3, brand.length)).toUpperCase();
    int num = 1000 + random.nextInt(9000);
    String letters =
        String.fromCharCode(65 + random.nextInt(26)) +
        String.fromCharCode(65 + random.nextInt(26));
    return "$short$num$letters";
  }

  void buyScratchCard() {
    if (coins < coupon_price) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Need $coupon_price coins")));
      return;
    }

    setState(() {
      coins -= coupon_price;
    });
    Color randomScratchColor =
        scratchColors[random.nextInt(scratchColors.length)];
    bool lose = random.nextInt(100) < 65;

    Map<String, String> reward = {};

    if (!lose) {
      final selected = couponList[random.nextInt(couponList.length)];

      reward = {
        "brand": selected["brand"]!,
        "offer": selected["offer"]!,
        "code": generateCouponCode(selected["brand"]!),
      };
    }

    bool alreadyClaimed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: SizedBox(
            width: 300,
            height: 320,
            child: Column(
              children: [
                const Text(
                  "Scratch Card 🎉",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Scratcher(
                    brushSize: 35,
                    threshold: 45,
                    color: randomScratchColor,

                    onThreshold: () {
                      if (!alreadyClaimed && !lose) {
                        alreadyClaimed = true;

                        setState(() {
                          rewards.add(reward);
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: lose
                            ? const Text(
                                "Better Luck\nNext Time",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    reward["offer"]!,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    reward["brand"]!,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      reward["code"]!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Done"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Coupon copied")));
  }

  void showCouponPopup(Map<String, String> reward) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reward["brand"]!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  reward["offer"]!,
                  style: const TextStyle(fontSize: 20, color: Colors.green),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    reward["code"]!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    minimumSize: const Size(200, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => copyCode(reward["code"]!),
                  icon: const Icon(Icons.copy, color: Colors.white),
                  label: const Text(
                    "Copy Code",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget rewardCard(Map<String, String> reward) {
    return GestureDetector(
      onTap: () => showCouponPopup(reward),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.local_offer, color: Colors.blue),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward["brand"]!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    reward["offer"]!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Rewards", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: ListView(
        children: [
          const SizedBox(height: 50),

          Image.asset("assets/images/coin.png", height: 250),

          const SizedBox(height: 30),

          Center(
            child: Text(
              "$coins",
              style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
            ),
          ),

          const Center(
            child: Text("Value Points", style: TextStyle(fontSize: 20)),
          ),

          const SizedBox(height: 50),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: buyScratchCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                "Buy Scratch Card ($coupon_price Coins)",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Coupons for you",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 10),

          rewards.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text("No rewards yet")),
                )
              : Column(
                  children: rewards
                      .map((reward) => rewardCard(reward))
                      .toList(),
                ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final String name;
  final String imagePath;

  const EditProfilePage({
    super.key,
    required this.name,
    required this.imagePath,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;

  late String imagePath;
  void showImagePickerDialog() {
    String tempImage = imagePath;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Select Profile Picture",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              tempImage = "assets/images/male.jpg";
                            });
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: tempImage == "assets/images/male.jpg"
                                      ? Border.all(color: Colors.blue, width: 3)
                                      : null,
                                ),
                                child: const CircleAvatar(
                                  radius: 35,
                                  backgroundImage: AssetImage(
                                    "assets/images/male.jpg",
                                  ),
                                ),
                              ),

                              if (tempImage == "assets/images/male.jpg")
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.blue,
                                    child: Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              tempImage = "assets/images/female.jpg";
                            });
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      tempImage == "assets/images/female.jpg"
                                      ? Border.all(color: Colors.blue, width: 3)
                                      : null,
                                ),
                                child: const CircleAvatar(
                                  radius: 35,
                                  backgroundImage: AssetImage(
                                    "assets/images/female.jpg",
                                  ),
                                ),
                              ),

                              if (tempImage == "assets/images/female.jpg")
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.blue,
                                    child: Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            imagePath = tempImage;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text("OK"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    imagePath = widget.imagePath;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: showImagePickerDialog,
              child: CircleAvatar(
                radius: 100,
                backgroundImage: AssetImage(imagePath),
                child: const Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.edit, size: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'name': nameController.text,
                    'image': imagePath,
                  });
                },
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Account extends StatelessWidget {
  final List<String> items = [
    "Change your password",
    "Reset your account",
    "Delete your account",
  ];
  Account({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account settings')),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(15),
              title: Text(items[index]),
              trailing: Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                switch (index) {
                  case 0:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChangePassword()),
                    );
                    break;

                  case 1:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ConfirmActionPage(isDelete: false),
                      ),
                    );
                    break;

                  case 2:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConfirmActionPage(isDelete: true),
                      ),
                    );
                    break;
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class ResetSuccessPage extends StatelessWidget {
  const ResetSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),

            const SizedBox(height: 20),

            const Text(
              "Account Reset \nSuccessful!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            Padding(
              padding: const EdgeInsets.all(50.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomePage(initialIndex: 0),
                    ),
                    (route) => false,
                  );
                },
                child: const Text(
                  "Start Fresh",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeleteSuccessPage extends StatelessWidget {
  const DeleteSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),

            const SizedBox(height: 20),
            const Text(
              "Account Deleted\nSuccessful!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.all(50.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                    (route) => false,
                  );
                },
                child: const Text(
                  "Go to Login",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfirmActionPage extends StatefulWidget {
  final bool isDelete;

  const ConfirmActionPage({super.key, required this.isDelete});

  @override
  State<ConfirmActionPage> createState() => _ConfirmActionPageState();
}

class _ConfirmActionPageState extends State<ConfirmActionPage> {
  bool _obscureCurrent = true;
  bool isLoading = false;
  String? errorMessage;
  final TextEditingController currentController = TextEditingController();

  @override
  void dispose() {
    currentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDelete ? "Delete Account" : "Reset Account"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                "For security, verify your current password first.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 30),

              const Text(
                "Current Password",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: currentController,
                obscureText: _obscureCurrent,
                decoration: inputDecoration("Enter current password").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrent = !_obscureCurrent;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : verifyPasswordAndConfirm,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> verifyPasswordAndConfirm() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    final currentInput = currentController.text.trim();
    if (currentInput.isEmpty) {
      setState(() {
        errorMessage = "All fields are required";
        isLoading = false;
      });
      return;
    }

    try {
      final userId = await AuthService().getCurrentUserId();
      if (!context.mounted) return;
      if (userId == null) {
        setState(() {
          errorMessage = "User not found";
          isLoading = false;
        });
        return;
      }

      final user = await ProfileService().getUser(userId);
      if (!context.mounted) return;
      if (user == null) {
        setState(() {
          errorMessage = "User not found";
          isLoading = false;
        });
        return;
      }

      final dbPassword = (user['password'] ?? '').toString().trim();
      if (hashPassword(currentInput) != dbPassword) {
        setState(() {
          errorMessage = "Current password is incorrect";
          isLoading = false;
        });
        return;
      }

      setState(() {
        isLoading = false;
      });

      final confirmed = await showConfirmDialog();
      if (!context.mounted || confirmed != true) return;

      if (widget.isDelete) {
        await deleteAccount(userId);
      } else {
        await resetAccount(userId);
      }
    } catch (e) {
      if (!context.mounted) return;
      setState(() {
        errorMessage = "Something went wrong";
        isLoading = false;
      });
    }
  }

  Future<bool?> showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.isDelete ? "Delete Account" : "Reset Account"),
          content: Text(
            widget.isDelete
                ? "Are you sure you want to DELETE your account?"
                : "Are you sure you want to RESET your account?",
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                minimumSize: const Size(120, 50),
              ),
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                minimumSize: const Size(120, 50),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Yes", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> resetAccount(int userId) async {
    await TaskService().deleteAllTasks(userId);
    await NoteService().deleteAllNotes(userId);
    await PasswordService().deleteAllPasswords(userId);
    await ProfileService().updateUser(userId, {'coins': 0});

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ResetSuccessPage()),
    );
  }

  Future<void> deleteAccount(int userId) async {
    await ProfileService().deleteUser(userId);

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DeleteSuccessPage()),
    );
  }
}

class ChangeMasterPassword extends StatefulWidget {
  const ChangeMasterPassword({super.key});

  @override
  State<ChangeMasterPassword> createState() => _ChangeMasterPasswordState();
}

InputDecoration inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
  );
}

class _ChangeMasterPasswordState extends State<ChangeMasterPassword> {
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final TextEditingController currentController = TextEditingController();
  final TextEditingController newController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  final List<TextEditingController> otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  String? errorMessage;
  bool isLoading = false;

  final ProfileService _profileService = ProfileService();

  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  String getEnteredPassword() {
    return otpControllers.map((e) => e.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Change Master Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              const Text(
                "Enter your current master password",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              if (errorMessage != null) ...[
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 60,
                    child: TextField(
                      controller: otpControllers[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF353535),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    setState(() {
                      errorMessage = null;
                      isLoading = true;
                    });

                    final enteredPassword = hashPassword(getEnteredPassword());
                    try {
                      final userId = await AuthService().getCurrentUserId();
                      if (!context.mounted) return;

                      if (userId == null) {
                        setState(() {
                          errorMessage = "User not found";
                          isLoading = false;
                        });
                        return;
                      }

                      final user = await _profileService.getUser(userId);

                      if (user == null) {
                        setState(() {
                          errorMessage = "User not found";
                          isLoading = false;
                        });
                        return;
                      }

                      final dbPassword = user['masterPassword'];
                      if (enteredPassword != dbPassword) {
                        setState(() {
                          errorMessage = "Incorrect master password";
                          isLoading = false;
                        });
                        return;
                      }

                      setState(() {
                        isLoading = false;
                      });

                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewMasterPasswordPage(),
                        ),
                      );
                    } catch (e) {
                      setState(() {
                        errorMessage = "Something went wrong";
                        isLoading = false;
                      });
                    }
                  },
                  child: const Text(
                    "Verify",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewMasterPasswordPage extends StatefulWidget {
  const NewMasterPasswordPage({super.key});

  @override
  State<NewMasterPasswordPage> createState() => _NewMasterPasswordPageState();
}

class _NewMasterPasswordPageState extends State<NewMasterPasswordPage> {
  double sliderPosition = 0;
  int d1 = 0, d2 = 0, d3 = 0, d4 = 0;
  String get enteredCode => "$d1$d2$d3$d4";
  final controller = FixedExtentScrollController(initialItem: 1000);
  final ProfileService _profileService = ProfileService();

  Widget numberWheel(ValueChanged<int> onSelected) {
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
        ],
      ),
    );
  }

  Future<bool?> showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Do you confirm the password?\n\n$enteredCode",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Master Password")),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/Lock.png', height: 300),

            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(child: numberWheel((v) => d1 = v)),
                Expanded(child: numberWheel((v) => d2 = v)),
                Expanded(child: numberWheel((v) => d3 = v)),
                Expanded(child: numberWheel((v) => d4 = v)),
              ],
            ),

            const SizedBox(height: 40),

            LayoutBuilder(
              builder: (context, constraints) {
                double sliderWidth = constraints.maxWidth;
                double knobSize = 60;
                double maxPosition = sliderWidth - knobSize - 10;

                return Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Text(
                          "Slide to Continue",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      Positioned(
                        left: sliderPosition,
                        child: GestureDetector(
                          onHorizontalDragUpdate: (details) async {
                            setState(() {
                              sliderPosition += details.delta.dx;

                              if (sliderPosition < 0) sliderPosition = 0;
                            });

                            if (sliderPosition > maxPosition) {
                              sliderPosition = maxPosition;

                              final confirm = await showConfirmDialog();

                              if (confirm == true) {
                                try {
                                  final userId =
                                      await AuthService().getCurrentUserId();

                                  if (userId == null) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("User not found"),
                                      ),
                                    );
                                    return;
                                  }

                                  final hashedPassword = hashPassword(
                                    enteredCode,
                                  );

                                  await _profileService.updateMasterPassword(
                                    userId,
                                    hashedPassword,
                                  );

                                  if (!context.mounted) return;

                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SuccessPage(),
                                    ),
                                    (route) => false,
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Error saving password"),
                                    ),
                                  );
                                }
                              }

                              setState(() {
                                sliderPosition = 0;
                              });
                            }
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.double_arrow),
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

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  final TextEditingController currentController = TextEditingController();
  final TextEditingController newController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;
  final ProfileService _profileService = ProfileService();
  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Change Master Password')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                "For security, verify your current password first.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 30),

              const Text(
                "Current Password",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: currentController,
                obscureText: _obscureCurrent,
                decoration: inputDecoration("Enter current password").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrent = !_obscureCurrent;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "New Password",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newController,
                obscureText: _obscureNew,
                decoration: inputDecoration("Enter new password").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNew = !_obscureNew;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Confirm Password",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                obscureText: _obscureConfirm,
                decoration: inputDecoration("Re-enter new password").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() {
                            errorMessage = null;
                            isLoading = true;
                          });
                          final currentInput = currentController.text.trim();
                          final newPass = newController.text.trim();
                          final confirm = confirmController.text.trim();
                          if (currentInput.isEmpty ||
                              newPass.isEmpty ||
                              confirm.isEmpty) {
                            setState(() {
                              errorMessage = "All fields are required";
                              isLoading = false;
                            });
                            return;
                          }

                          if (newPass != confirm) {
                            setState(() {
                              errorMessage = "Passwords do not match";
                              isLoading = false;
                            });
                            return;
                          }
                          final current = hashPassword(currentInput);
                          try {
                            final userId =
                                await AuthService().getCurrentUserId();
                            if (!context.mounted) return;
                            if (userId == null) {
                              setState(() {
                                errorMessage = "User not found";
                                isLoading = false;
                              });
                              return;
                            }

                            final user = await _profileService.getUser(userId);
                            if (!context.mounted) return;
                            if (user == null) {
                              setState(() {
                                errorMessage = "User not found";
                                isLoading = false;
                              });
                              return;
                            }
                            final dbPassword = (user['password'] ?? '')
                                .toString()
                                .trim();

                            if (current != dbPassword) {
                              setState(() {
                                errorMessage = "Current password is incorrect";
                                isLoading = false;
                              });
                              return;
                            }

                            setState(() {
                              isLoading = false;
                            });
                            final confirmed = await showConfirmDialog();
                            if (!context.mounted || confirmed != true) return;
                            setState(() {
                              isLoading = true;
                            });

                            await _profileService.updateUser(userId, {
                              'password': hashPassword(newPass),
                            });
                            if (!context.mounted) return;
                            setState(() {
                              isLoading = false;
                              errorMessage = null;
                            });
                            currentController.clear();
                            newController.clear();
                            confirmController.clear();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SuccessPage(),
                              ),
                              (route) => false,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            setState(() {
                              errorMessage = "Something went wrong";
                              isLoading = false;
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Update Password"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Password"),
          content: const Text(
            "Are you sure you want to change your password?",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                minimumSize: const Size(120, 50),
              ),
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                minimumSize: const Size(120, 50),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Yes", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),

              const SizedBox(height: 20),

              const Text(
                "Password Changed \nSuccessful!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              Padding(
                padding: const EdgeInsets.all(50.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(initialIndex: 3),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    "Go to Profile Page",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
