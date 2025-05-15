
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage   = FirebaseStorage.instance;

  final nameController = TextEditingController();
  List<String> selectedLanguages = [];
  Uint8List? webImageBytes;
  XFile?     pickedFile;
  bool       isLoading     = false;
  String?    currentPhotoUrl;

  final languageOptions = ['BIM','BISINDO','English','Braille'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          nameController.text =
            data['displayName'] ?? data['name'] ?? user.displayName ?? '';
          if (data['preferredLanguages'] != null) {
            selectedLanguages = List<String>.from(data['preferredLanguages']);
          }
          currentPhotoUrl = (data['photoUrl'] ?? user.photoURL)?.trim();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        nameController.text = _auth.currentUser?.displayName ?? '';
        currentPhotoUrl    = _auth.currentUser?.photoURL?.trim();
      });
    }
  }

  /// ──────── UPDATE FOR TESTING ON WEB ────────
  /// If we're on Web and have picked bytes, we just convert to a
  /// data-URI and return that.  Firestore will get a base-64 string
  /// instead of a Storage URL.
  Future<String?> _uploadProfileImage(String uid) async {
    // nothing new picked?
    if (pickedFile == null && webImageBytes == null) {
      return currentPhotoUrl;
    }

    // Web testing: embed the bytes as a data URI
    if (kIsWeb && webImageBytes != null) {
      final b64 = base64Encode(webImageBytes!);
      return 'data:image/jpeg;base64,$b64';
    }

    // Mobile/Desktop: still upload to Firebase Storage
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('profile_pictures/${uid}_$ts.jpg');
      final meta = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'max-age=3600',
        customMetadata: {
          'userUid': uid,
          'uploadedAt': ts.toString(),
        },
      );

      UploadTask task = pickedFile != null
        ? ref.putFile(File(pickedFile!.path), meta)
        : ref.putData(webImageBytes!, meta);

      final snap = await task.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Upload timed out'),
      );

      String url = (await snap.ref.getDownloadURL()).trim();
      // small delay on web so upload fully propagates
      if (kIsWeb) await Future.delayed(const Duration(seconds: 1));
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return currentPhotoUrl;
    }
  }

  Future<void> _pickImage() async {
    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (img == null) return;
      if (!mounted) return;

      if (kIsWeb) {
        webImageBytes = await img.readAsBytes();
        pickedFile    = null;
      } else {
        pickedFile    = img;
        webImageBytes = null;
      }
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (!mounted) return;

    setState(() => isLoading = true);
    try {
      final photoURL = await _uploadProfileImage(user.uid);
      final data = {
        'displayName': nameController.text.trim(),
        'name'       : nameController.text.trim(),
        'preferredLanguages': selectedLanguages,
        'updatedAt'  : FieldValue.serverTimestamp(),
        if (photoURL != null) 'photoUrl': photoURL,
      };

      await user.updateDisplayName(nameController.text.trim());
      if (photoURL != null) await user.updatePhotoURL(photoURL);
      await _firestore.collection('users').doc(user.uid).update(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      await Future.delayed(const Duration(seconds:1));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// ──────── UPDATED AVATAR BUILDER ────────
  /// Now handles:
  ///  • Web-memory images (immediately after pick)
  ///  • Local-file images
  ///  • Base-64 “data:” URIs in `currentPhotoUrl`
  ///  • Fallback network or placeholder
  Widget _buildAvatar() {
    // memory from web pick
    if (kIsWeb && webImageBytes != null) {
      return CircleAvatar(radius:50, backgroundImage: MemoryImage(webImageBytes!));
    }
    // local file on mobile
    if (pickedFile != null) {
      return CircleAvatar(radius:50, backgroundImage: FileImage(File(pickedFile!.path)));
    }
    // base-64 string from Firestore
    if (currentPhotoUrl != null && currentPhotoUrl!.startsWith('data:image')) {
      final b64 = currentPhotoUrl!.split(',').last;
      final bytes = base64Decode(b64);
      return CircleAvatar(radius:50, backgroundImage: MemoryImage(bytes));
    }
    // network URL (once your Storage CORS is fixed or in mobile)
    if ((currentPhotoUrl ?? '').isNotEmpty) {
      return CircleAvatar(
        radius:50,
        backgroundColor:Colors.grey.shade200,
        child: ClipOval(
          child: Image.network(
            currentPhotoUrl!,
            width:100, height:100, fit:BoxFit.cover,
            loadingBuilder:(_,child,prog)=> prog==null
              ? child
              : Center(child:CircularProgressIndicator(
                  value: prog.expectedTotalBytes!=null
                    ? prog.cumulativeBytesLoaded/prog.expectedTotalBytes!
                    : null)),
            errorBuilder:(_,__,___)=> const Icon(Icons.person,size:50,color:Colors.grey),
          ),
        ),
      );
    }
    // fallback placeholder
    return const CircleAvatar(
      radius:50,
      backgroundColor:Color(0xFFF45B69),
      child:Icon(Icons.person,size:50,color:Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: primary,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children:[
                _buildAvatar(),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt, color: Color(0xFFF45B69)),
                  label: const Text('Change Photo'),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Preferred Languages:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: languageOptions.map((lang) {
                    final sel = selectedLanguages.contains(lang);
                    return FilterChip(
                      label: Text(lang),
                      selected: sel,
                      selectedColor: primary.withOpacity(0.3),
                      checkmarkColor: primary,
                      onSelected: (v) {
                        if (!mounted) return;
                        setState(() {
                          if (v) selectedLanguages.add(lang);
                          else selectedLanguages.remove(lang);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
                const SizedBox(height: 24),
              ]
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFF45B69)),
              ),
            ),
        ]
      ),
    );
  }
}