import 'package:flutter/material.dart';
import '../login/registration_page.dart';
import '../login/forgot_password_page.dart';
import '../dashboard/dashboard_page.dart';
import '../admin_dashboard/admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool rememberMe = false;
  bool showPassword = false;
  bool signLanguageMode = false;
  bool brailleMode = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void showAccessibilityModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Accessibility Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: const Text('Enable Sign Language Mode (Visuals)'),
                value: signLanguageMode,
                onChanged: (val) {
                  setState(() => signLanguageMode = val);
                },
              ),
              SwitchListTile(
                title: const Text('Enable Braille Mode (Screen Reader & Keyboard Prep)'),
                value: brailleMode,
                onChanged: (val) {
                  setState(() => brailleMode = val);
                },
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Accessibility settings applied')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF45B69),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Apply Settings'),
              ),
            ],
          ),
        );
      },
    );
  }

  void handleLogin() {
    // TODO: Replace with real Firebase auth logic
    bool isAdmin = emailController.text == 'admin@example.com';
    if (isAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Color(0xFFF45B69)),
                const SizedBox(height: 24),
                const Text('Welcome Back!',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Sign in to your account',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: showAccessibilityModal,
                    icon: const Icon(Icons.accessibility, color: Color(0xFFF45B69)),
                    label: const Text('Accessibility Options',
                        style: TextStyle(color: Color(0xFFF45B69))),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined),
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() => showPassword = !showPassword);
                      },
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (value) {
                        setState(() {
                          rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text('Remember Me'),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                        );
                      },
                      child: const Text('Forgot Password?',
                          style: TextStyle(color: Color(0xFFF45B69))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
                const SizedBox(height: 24),
                const Text('OR',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialIcon(Icons.g_mobiledata, Colors.red, 'Google'),
                    const SizedBox(width: 24),
                    _buildSocialIcon(Icons.apple, Colors.black, 'Apple'),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegistrationPage()),
                    );
                  },
                  child: const Text('Don\'t have an account? Register here.',
                      style: TextStyle(color: Color(0xFFF45B69))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, String label) {
    return InkWell(
      onTap: () {
        print('$label icon clicked!');
        // TODO: Add $label sign-in logic here
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}