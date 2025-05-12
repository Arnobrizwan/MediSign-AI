

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dashboard/dashboard_page.dart';                      
import '../admin_dashboard/admin_dashboard_page.dart';         
import '../doctor/doctor_dashboard_page.dart';                  
import '../ambulance/ambulance_dashboard_page.dart';            
import 'forgot_password_page.dart';
import 'registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = false;
  bool showPassword = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      rememberMe = prefs.getBool('remember_me') ?? false;
      if (rememberMe) {
        emailController.text = prefs.getString('saved_email') ?? '';
        passwordController.text = prefs.getString('saved_password') ?? '';
      }
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

  Future<void> _routeByRole(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final role = snap.data()?['role'] as String? ?? 'patient';

    Widget destination;
    switch (role) {
      case 'admin':
        destination = const AdminDashboardPage();
        break;
      case 'doctor':
        destination = const DoctorDashboardPage();
        break;
      case 'ambulance':
        destination = const AmbulanceDashboardPage();
        break;
      default:
        destination = const PatientDashboardPage();
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (_) => false,
    );
  }

  Future<void> _handleEmailLogin() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      await _saveCredentials();
      await _routeByRole(cred.user!.uid);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final googleUser = await GoogleSignIn(scopes: ['email', 'profile']).signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      await _saveUserToFirestore(cred.user, 'google');
      await _saveCredentials();
      await _routeByRole(cred.user!.uid);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleAppleLogin() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final appleCred = await SignInWithApple.getAppleIDCredential(
        scopes: [ AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName ],
      );
      final oauthCred = OAuthProvider("apple.com").credential(
        idToken: appleCred.identityToken,
        accessToken: appleCred.authorizationCode,
      );
      final cred = await _auth.signInWithCredential(oauthCred);
      await _saveUserToFirestore(cred.user, 'apple');
      await _saveCredentials();
      await _routeByRole(cred.user!.uid);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apple sign-in failed')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
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
        'role': 'patient',  // default new users to patient
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showAccessibilityModal() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Accessibility Options',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          // your accessibility toggles...
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
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF45B69);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline, size: 64, color: primaryColor),
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
                  onPressed: _showAccessibilityModal,
                  icon: const Icon(Icons.accessibility, color: primaryColor),
                  label: const Text('Accessibility Options',
                      style: TextStyle(color: primaryColor)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => showPassword = !showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: (v) => setState(() => rememberMe = v ?? false),
                ),
                const Text('Remember Me'),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                  child: const Text('Forgot Password?', style: TextStyle(color: primaryColor)),
                ),
              ]),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isLoading ? null : _handleEmailLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Continue', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              const SizedBox(height: 24),
              const Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  icon: const Icon(Icons.g_mobiledata),
                  color: Colors.red,
                  iconSize: 36,
                  onPressed: isLoading ? null : _handleGoogleLogin,
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.apple),
                  color: Colors.black,
                  iconSize: 36,
                  onPressed: isLoading ? null : _handleAppleLogin,
                ),
              ]),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationPage())),
                child: const Text('Don’t have an account? Register here.',
                    style: TextStyle(color: primaryColor)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}