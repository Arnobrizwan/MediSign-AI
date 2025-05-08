import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../login/login_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String? selectedLanguage;
  File? profileImage;
  Uint8List? webImageBytes;

  bool agreedToTerms = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> generatePatientId() async {
    final counterRef = _firestore.collection('counters').doc('patientCounter');
    final counterSnap = await counterRef.get();

    int currentCount = counterSnap.exists ? counterSnap['count'] : 0;
    int newCount = currentCount + 1;

    await counterRef.set({'count': newCount});

    return 'PAT-${newCount.toString().padLeft(3, '0')}';
  }

  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          webImageBytes = bytes;
          profileImage = null;
        });
      } else {
        setState(() {
          profileImage = File(pickedFile.path);
          webImageBytes = null;
        });
      }
    }
  }

  Future<String?> uploadProfileImage(String uid) async {
    if (profileImage == null && webImageBytes == null) return null;
    final ref = _storage.ref().child('profile_pictures/$uid.jpg');
    UploadTask uploadTask;

    if (kIsWeb && webImageBytes != null) {
      uploadTask = ref.putData(webImageBytes!);
    } else if (profileImage != null) {
      uploadTask = ref.putFile(profileImage!);
    } else {
      return null;
    }

    await uploadTask;
    return await ref.getDownloadURL();
  }

  Future<void> handleRegister() async {
    if (!agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Conditions')),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      String? photoURL;

      if (user != null) {
        String patientId = await generatePatientId();
        photoURL = await uploadProfileImage(user.uid);

        await user.updateDisplayName(nameController.text.trim());
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'patientId': patientId,
          'name': nameController.text.trim(),
          'email': user.email,
          'preferredLanguage': selectedLanguage ?? 'None',
          'photoUrl': photoURL ?? '',
          'createdAt': Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Please log in.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: agreedToTerms ? pickProfileImage : null,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  child: ClipOval(
                    child: (kIsWeb && webImageBytes != null)
                        ? Image.memory(webImageBytes!, width: 100, height: 100, fit: BoxFit.cover)
                        : (profileImage != null)
                            ? Image.file(profileImage!, width: 100, height: 100, fit: BoxFit.cover)
                            : const Icon(Icons.camera_alt, size: 32, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Nice to see you!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Create your account', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  labelText: 'Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() => showPassword = !showPassword);
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: !showConfirmPassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() => showConfirmPassword = !showConfirmPassword);
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedLanguage,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.language),
                  labelText: 'Preferred Sign Language',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                items: const [
                  DropdownMenuItem(value: 'BIM', child: Text('Malaysian Sign Language (BIM)')),
                  DropdownMenuItem(value: 'BISINDO', child: Text('Indonesian Sign Language (BISINDO)')),
                  DropdownMenuItem(value: 'None', child: Text('None/Other')),
                ],
                onChanged: (value) {
                  setState(() => selectedLanguage = value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: agreedToTerms,
                    onChanged: (value) {
                      setState(() => agreedToTerms = value ?? false);
                    },
                  ),
                  const Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: 'I agree with '),
                      TextSpan(text: 'Terms & Conditions', style: TextStyle(color: Colors.blue)),
                    ])),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Register', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
