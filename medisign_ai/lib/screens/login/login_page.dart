import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dashboard/dashboard_page.dart';
import '../admin_dashboard/admin_dashboard_page.dart';
import 'registration_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  bool showPassword = false;
  bool signLanguageMode = false;
  bool brailleMode = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('saved_email') ?? '';
      passwordController.text = prefs.getString('saved_password') ?? '';
      rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('saved_email', emailController.text.trim());
      await prefs.setString('saved_password', passwordController.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  void showAccessibilityModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Accessibility Options',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Apply Settings'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> handleLogin() async {
    setState(() => isLoading = true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      await _saveCredentials();
      await _routeUserByRole(userCredential.user);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> handleGoogleLogin() async {
    setState(() => isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      await _saveUserToFirestore(userCredential.user, 'google');
      await _saveCredentials();
      await _routeUserByRole(userCredential.user);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> handleAppleLogin() async {
    setState(() => isLoading = true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);
      await _saveUserToFirestore(userCredential.user, 'apple');
      await _saveCredentials();
      await _routeUserByRole(userCredential.user);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apple sign-in failed')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String> _fetchWelcomeMessageFromGemini(String email) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getGeminiWelcomeMessage')
          .call({'email': email});
      return result.data['message'] ?? 'Welcome!';
    } catch (e) {
      print('❌ Error fetching Gemini welcome message: $e');
      return 'Welcome!';
    }
  }

  Future<void> _routeUserByRole(User? user) async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User record not found in Firestore.')),
      );
      return;
    }

    String role = doc.data()?['role'] ?? 'user';

    String welcomeMessage = await _fetchWelcomeMessageFromGemini(user.email ?? '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(welcomeMessage)),
    );

    if (role == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientDashboardPage()));
    }
  }

  Future<void> _saveUserToFirestore(User? user, String provider) async {
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? '',
        'provider': provider,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
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
                        Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordPage()));
                      },
                      child: const Text('Forgot Password?',
                          style: TextStyle(color: Color(0xFFF45B69))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Continue',
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
                const SizedBox(height: 24),
                const Text('OR',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialIcon(Icons.g_mobiledata, Colors.red, 'Google', handleGoogleLogin),
                    const SizedBox(width: 24),
                    _buildSocialIcon(Icons.apple, Colors.black, 'Apple', handleAppleLogin),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RegistrationPage()));
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

  Widget _buildSocialIcon(IconData icon, Color color, String label, Function() onTap) {
    return InkWell(
      onTap: isLoading ? null : onTap,
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