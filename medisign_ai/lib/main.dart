import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart'; // Import splash screen
import 'screens/login/login_page.dart';
import 'screens/login/registration_page.dart';
import 'screens/login/forgot_password_page.dart';
import 'screens/dashboard/dashboard_page.dart';
import 'screens/admin_dashboard/admin_dashboard_page.dart';
import 'screens/sign_translate/sign_translate_page.dart';
import 'screens/conversation_mode/conversation_mode_page.dart';
import 'screens/accessibility_settings/accessibility_settings_page.dart';
import 'screens/transcript_history/transcript_history_page.dart';
import 'screens/tutorial_support/tutorial_support_page.dart';
import 'screens/health_checkin/health_checkin_page.dart';
import 'screens/patient_locator/patient_locator_page.dart';
import 'screens/telemedicine/telemedicine_page.dart';
import 'screens/learning_gamified/learning_gamified_page.dart';
import 'screens/family_portal/family_portal_page.dart';
import 'screens/admin_dashboard/session_monitoring_page.dart';
import 'screens/admin_dashboard/translation_review_page.dart';
import 'screens/admin_dashboard/content_management_page.dart';
import 'screens/admin_dashboard/audit_compliance_page.dart';
import 'screens/appointment_center/appointment_center_page.dart';
import 'screens/medical_records/medical_records_page.dart';
import 'screens/prescription_management/prescriptions_page.dart';
import 'screens/hospital_guide/hospital_guide_page.dart';
import 'screens/billing/billing_page.dart';
import 'screens/login/edit_profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set auth persistence for web
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (e) {
    print('Error setting auth persistence: $e');
  }
  
  runApp(const MediSignApp());
}

class MediSignApp extends StatelessWidget {
  const MediSignApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediSign AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF45B69)),
        useMaterial3: true,
      ),
      // Choose either SplashScreen or WebAuthWrapper as the home
      home: const SplashScreen(), // Use splash screen
      // home: const WebAuthWrapper(), // Or use direct auth wrapper
      routes: {
        '/login': (context) => const LoginPage(),
        '/registration': (context) => const RegistrationPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/dashboard': (context) => const PatientDashboardPage(),
        '/admin_dashboard': (context) => const AdminDashboardPage(),
        '/sign_translate': (context) => const SignTranslatePage(),
        '/conversation_mode': (context) => const ConversationModePage(),
        '/accessibility_settings': (context) => const AccessibilitySettingsPage(),
        '/transcript_history': (context) => const TranscriptHistoryPage(),
        '/tutorial_support': (context) => const TutorialSupportPage(),
        '/health_checkin': (context) => const HealthCheckinPage(),
        '/patient_locator': (context) => const PatientLocatorPage(),
        '/telemedicine': (context) => const TelemedicinePage(),
        '/learning_gamified': (context) => const LearningGamifiedPage(),
        '/family_portal': (context) => const FamilyPortalPage(),
        '/session_monitoring': (context) => const SessionMonitoringPage(),
        '/translation_review': (context) => const TranslationReviewPage(),
        '/admin_manage_content': (context) => const ContentManagementPage(),
        '/admin_audit_compliance': (context) => const AuditCompliancePage(),
        '/appointment_center': (context) => const AppointmentCenterPage(),
        '/medical_records': (context) => const MedicalRecordsPage(),
        '/prescription_management': (context) => const PrescriptionsPage(),
        '/hospital_guide': (context) => const HospitalGuidePage(),
        '/billing': (context) => const BillingPage(),
        '/editProfile': (context) => const EditProfilePage(),
      },
    );
  }
}

class WebAuthWrapper extends StatelessWidget {
  const WebAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Connection state waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF45B69),
              ),
            ),
          );
        }
        
        // User logged in
        if (snapshot.hasData && snapshot.data != null) {
          return const DashboardRouter();
        }
        
        // User not logged in
        return const LoginPage();
      },
    );
  }
}

class DashboardRouter extends StatelessWidget {
  const DashboardRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const LoginPage();
    }
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
            // Timeout fallback - return empty doc
            return FirebaseFirestore.instance.collection('users').doc('dummy').get();
          }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF45B69),
              ),
            ),
          );
        }
        
        // Error or timeout
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          // Default to patient dashboard on error
          return const PatientDashboardPage();
        }
        
        // Check user role
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final role = userData?['role'] ?? 'user';
        
        if (role == 'admin') {
          return const AdminDashboardPage();
        } else {
          return const PatientDashboardPage();
        }
      },
    );
  }
}