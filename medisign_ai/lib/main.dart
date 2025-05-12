import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

import 'providers/theme_provider.dart';
import 'providers/accessibility_provider.dart';

import 'screens/braille_interaction/braille_interaction_page.dart';

import 'screens/splash_screen.dart';
import 'screens/login/login_page.dart';
import 'screens/login/registration_page.dart';
import 'screens/login/forgot_password_page.dart';
import 'screens/login/edit_profile_page.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Keep users signed in on Web
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (_) {}

  runApp(
    MultiProvider(
      providers: [
        // 1️⃣ AccessibilityProvider at the top:
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),

        // 2️⃣ ThemeProvider follows AccessibilityProvider:
        ChangeNotifierProxyProvider<AccessibilityProvider, ThemeProvider>(
          create: (_) => ThemeProvider(),
          update: (_, accessibility, themeProvider) {
            themeProvider!..setTheme(accessibility.theme);
            return themeProvider;
          },
        ),
      ],
      child: const MediSignApp(),
    ),
  );
}

class MediSignApp extends StatelessWidget {
  const MediSignApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Watch for changes:
    final themeData = context.watch<ThemeProvider>().themeData;
    final fontScale =
        context.watch<AccessibilityProvider>().fontSize / 16.0;

    return MaterialApp(
      title: 'MediSign AI',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: fontScale),
          child: child!,
        );
      },
      home: const SplashScreenWithAccessibility(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/registration': (_) => const RegistrationPage(),
        '/forgot_password': (_) => const ForgotPasswordPage(),
        '/dashboard': (_) => const PatientDashboardPage(),
        '/admin_dashboard': (_) => const AdminDashboardPage(),
        '/sign_translate': (_) => const SignTranslatePage(),
        '/conversation_mode': (_) => const ConversationModePage(),
        '/accessibility_settings': (_) => const AccessibilitySettingsPage(),
        '/transcript_history': (_) => const TranscriptHistoryPage(),
        '/tutorial_support': (_) => const TutorialSupportPage(),
        '/health_checkin': (_) => const HealthCheckinPage(),
        '/patient_locator': (_) => const PatientLocatorPage(),
        '/telemedicine': (_) => const TelemedicinePage(),
        '/learning_gamified': (_) => const LearningGamifiedPage(),
        '/family_portal': (_) => const FamilyPortalPage(),
        '/session_monitoring': (_) => const SessionMonitoringPage(),
        '/translation_review': (_) => const TranslationReviewPage(),
        '/admin_manage_content': (_) => const ContentManagementPage(),
        '/admin_audit_compliance': (_) => const AuditCompliancePage(),
        '/appointment_center': (_) => const AppointmentCenterPage(),
        '/medical_records': (_) => const MedicalRecordsPage(),
        '/prescription_management': (_) => const PrescriptionsPage(),
        '/hospital_guide': (_) => const HospitalGuidePage(),
        '/billing': (ctx) {
    // Grab the current user’s ID (or displayName) however you like:
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return BillingPage(patientId: uid);
  },
        '/editProfile': (_) => const EditProfilePage(),
      },
    );
  }
}

class SplashScreenWithAccessibility extends StatefulWidget {
  const SplashScreenWithAccessibility({Key? key}) : super(key: key);
  @override
  State<SplashScreenWithAccessibility> createState() =>
      _SplashScreenWithAccessibilityState();
}

class _SplashScreenWithAccessibilityState
    extends State<SplashScreenWithAccessibility> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final access =
        Provider.of<AccessibilityProvider>(context, listen: false);

    if (FirebaseAuth.instance.currentUser != null) {
      await access.loadSettings();
    }

    // No more manual theme.setTheme(...) call needed!

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WebAuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}

class WebAuthWrapper extends StatelessWidget {
  const WebAuthWrapper({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snap.hasData ? const DashboardRouter() : const LoginPage();
      },
    );
  }
}

class DashboardRouter extends StatelessWidget {
  const DashboardRouter({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginPage();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10)),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || !snap.data!.exists) {
          return const PatientDashboardPage();
        }
        final data = snap.data!.data() as Map<String, dynamic>;
        return data['role'] == 'admin'
            ? const AdminDashboardPage()
            : const PatientDashboardPage();
      },
    );
  }
}