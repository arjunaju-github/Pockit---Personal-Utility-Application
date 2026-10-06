import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'database/db_helper.dart';
import 'forgot_otp_page.dart';
import 'homepage.dart';
import 'dart:math';
import '../services/email_service.dart';
import 'otp_verify_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

enum AuthForm { login, signup, forgot }

class _AuthPageState extends State<AuthPage> {
  TextEditingController forgotEmailController = TextEditingController();
  String? signupError;
  AuthForm currentForm = AuthForm.login;
  TextEditingController nameController = TextEditingController();
  TextEditingController signupEmailController = TextEditingController();
  TextEditingController signupPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureConfirmPassword = true;

  String? validateEmail(String email) {
    if (email.isEmpty) {
      return "Email is required";
    }

    // Simple email pattern
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    if (!emailRegex.hasMatch(email)) {
      return "Enter a valid email";
    }

    return null; // ✅ valid
  }

  void switchForm(AuthForm form) {
    setState(() {
      currentForm = form;
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: SingleChildScrollView(child: getFormWidget())),
    );
  }

  Widget getFormWidget() {
    switch (currentForm) {
      case AuthForm.login:
        return buildLoginForm();
      case AuthForm.signup:
        return buildSignUpForm();
      case AuthForm.forgot:
        return buildForgotForm();
    }
  }

  // ================= LOGIN =================
  Widget buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 50),

          /// LOGO
          Center(child: Image.asset('assets/images/branding.png', width: 300)),

          const SizedBox(height: 20),
          const Text(
            "Login",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 30),

          TextField(
            controller: emailController,
            decoration: inputDecoration("Enter your email"),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: passwordController,
            obscureText: _obscureLoginPassword,
            decoration: inputDecoration("Enter your password").copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureLoginPassword = !_obscureLoginPassword;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 30),

          ElevatedButton(
            style: buttonStyle(),
            onPressed: () async {
              final emailError = validateEmail(emailController.text.trim());
              final password = passwordController.text.trim();

              if (emailError != null) {
                showMessage(emailError);
                return;
              }

              if (password.isEmpty) {
                showMessage("Password is required");
                return;
              }

              final error = await AuthService().login(
                emailController.text.trim(),
                password,
              );

              if (error == null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', true);

                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
                );
              } else {
                showMessage(error);
              }
            },
            child: const Text(
              "Login",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),

          Center(
            child: TextButton(
              onPressed: () => switchForm(AuthForm.forgot),
              child: const Text("Forgot Password?"),
            ),
          ),
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 10)),
            ],
          ),
          Center(
            child: TextButton(
              onPressed: () => switchForm(AuthForm.signup),
              child: const Text("Don't have an account? Sign Up"),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SIGNUP =================
  Widget buildSignUpForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          /// LOGO
          Center(child: Image.asset('assets/images/branding.png', width: 300)),

          const SizedBox(height: 20),
          const Text(
            "Create an Account",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          if (signupError != null)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 7),
              child: Text(
                signupError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 30),

          TextField(
            controller: nameController,
            decoration: inputDecoration("Enter your name"),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: signupEmailController,
            decoration: inputDecoration("Enter your email"),
          ),


          const SizedBox(height: 20),

          TextField(
            controller: signupPasswordController,
            obscureText: _obscureSignupPassword,
            decoration: inputDecoration("Enter your password").copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignupPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureSignupPassword = !_obscureSignupPassword;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: inputDecoration("Re-enter your password").copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// TERMS
          Row(
            children: [
              Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                "I accept the terms and privacy policy",
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 30),

          ElevatedButton(
            style: buttonStyle(),
            onPressed: () async {
              setState(() {
                signupError = null;
              });

              final name = nameController.text.trim();
              final email = signupEmailController.text.trim();
              final password = signupPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();
              final emailError = validateEmail(email);

              if (name.isEmpty) {
                setState(() {
                  signupError = "Name is required";
                });
                return;
              }
              final nameRegex = RegExp(r'^[a-zA-Z ]+$');

              if (!nameRegex.hasMatch(name)) {
                setState(() {
                  signupError = "Name can contain only alphabets and spaces";
                });
                return;
              }
              if (emailError != null) {
                setState(() {
                  signupError = emailError;
                });
                return;
              }

              if (password.isEmpty) {
                setState(() {
                  signupError = "Password is required";
                });
                return;
              }

              if (password.length < 6) {
                setState(() {
                  signupError = "Password must be at least 6 characters";
                });
                return;
              }

              if (confirmPassword.isEmpty) {
                setState(() {
                  signupError = "Confirm password is required";
                });
                return;
              }

              if (password != confirmPassword) {
                setState(() {
                  signupError = "Passwords do not match";
                });
                return;
              }

              final error = await AuthService().checkEmailExists(email);

              if (error != null) {
                setState(() {
                  signupError = error;
                });
                return;
              }

              String otp = (100000 + Random().nextInt(900000)).toString();

              try {
                await EmailService.sendOtp(email, otp);
              } catch (e) {
                if (!context.mounted) return;
                setState(() {
                  signupError = e.toString();
                });
                return;
              }

              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtpVerifyPage(
                    otp: otp,
                    name: name,
                    email: email,
                    password: password,
                  ),
                ),
              );
            },
            child: const Text("Sign up", style: TextStyle(color: Colors.white)),
          ),

          const SizedBox(height: 30),

          /// DIVIDER
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 10)),
            ],
          ),

          Center(
            child: TextButton(
              onPressed: () => switchForm(AuthForm.login),
              child: const Text("Already have an account? Log in"),
            ),
          ),
        ],
      ),
    );
  }

  // ================= FORGOT =================
  Widget buildForgotForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          /// LOGO
          Center(child: Image.asset('assets/images/branding.png', width: 300)),

          const SizedBox(height: 20),

          const Text(
            "Forgot Password",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 30),

          TextField(
            controller: forgotEmailController,
            decoration: inputDecoration("Enter your email"),
          ),

          const SizedBox(height: 30),

          ElevatedButton(
            style: buttonStyle(),
            onPressed: () async {
              final email = forgotEmailController.text.trim();
              final emailError = validateEmail(email);

              if (emailError != null) {
                showMessage(emailError);
                return;
              }

              final db = await DBHelper.instance.database;

              final result = await db.query(
                'users',
                where: 'email = ?',
                whereArgs: [email],
              );

              if (result.isEmpty) {
                showMessage("Email not found");
                return;
              }

              String otp = (100000 + Random().nextInt(900000)).toString();

              try {
                await EmailService.sendOtp(email, otp);
              } catch (e) {
                if (!context.mounted) return;
                showMessage(e.toString());
                return;
              }

              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ForgotOtpPage(email: email, otp: otp),
                ),
              );
            },
            child: const Text(
              "Reset Password",
              style: TextStyle(color: Colors.white),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: TextButton(
              onPressed: () => switchForm(AuthForm.login),
              child: const Text("Back to Login"),
            ),
          ),
        ],
      ),
    );
  }

  // ================= COMMON =================
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

  ButtonStyle buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2C2C2C),
      minimumSize: const Size(double.infinity, 55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class SignupSuccessPage extends StatelessWidget {
  const SignupSuccessPage({super.key});

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
                "Signup Successful!",
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AuthPage()),
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
      ),
    );
  }
}

class SignupProfilePicturePage extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const SignupProfilePicturePage({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<SignupProfilePicturePage> createState() =>
      _SignupProfilePicturePageState();
}

class _SignupProfilePicturePageState extends State<SignupProfilePicturePage> {
  String imagePath = "assets/images/male.jpg";

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
                        /// MALE
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
                                  radius: 50,
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

                        /// FEMALE
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
                                  radius: 50,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Profile Picture")),
      body: Center(
        // ✅ CENTERED FIX
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// PROFILE IMAGE WITH EDIT ICON (same as EditProfile)
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

            const SizedBox(height: 40),

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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetMasterPasswordPage(
                        name: widget.name,
                        email: widget.email,
                        password: widget.password,
                        imagePath: imagePath,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Confirm",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SetMasterPasswordPage extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String imagePath;

  const SetMasterPasswordPage({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.imagePath,
  });

  @override
  State<SetMasterPasswordPage> createState() => _SetMasterPasswordPageState();
}

class _SetMasterPasswordPageState extends State<SetMasterPasswordPage> {
  double sliderPosition = 0;

  int d1 = 0, d2 = 0, d3 = 0, d4 = 0;

  String get enteredCode => "$d1$d2$d3$d4";

  final controller = FixedExtentScrollController(initialItem: 1000);

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
                Navigator.pop(context, false); // ❌ cancel
              },
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true); // ✅ confirm
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

            /// SAME SLIDER
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
                                final error = await AuthService().signup(
                                  name: widget.name,
                                  email: widget.email,
                                  password: widget.password,
                                  masterPassword: enteredCode,
                                  profileImage: widget.imagePath,
                                );

                                if (error == null) {
                                  if (!context.mounted) return;

                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignupSuccessPage(),
                                    ),
                                    (route) => false,
                                  );
                                } else {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error)),
                                  );
                                }
                              }

                              // reset slider if cancelled
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
