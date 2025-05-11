
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

import 'providers/theme_provider.dart';
import 'providers/accessibility_provider.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Web persistence
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (_) {}

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
      ],
      child: const MediSignApp(),
    ),
  );
}

class MediSignApp extends StatelessWidget {
  const MediSignApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AccessibilityProvider>(
      builder: (context, themeProvider, accessibilityProvider, child) {
        // Whenever accessibility.theme changes, apply to app theme
        accessibilityProvider.addListener(() {
          themeProvider.setTheme(accessibilityProvider.theme);
        });

        return MaterialApp(
          title: 'MediSign AI',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          builder: (context, child) {
            final scale = accessibilityProvider.fontSize / 16.0;
            return MediaQuery(
              data:
                  MediaQuery.of(context).copyWith(textScaleFactor: scale),
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
            '/billing': (_) => const BillingPage(),
            '/editProfile': (_) => const EditProfilePage(),
          },
        );
      },
    );
  }
}

/// Splash screen that loads settings, applies the default theme, then routes
class SplashScreenWithAccessibility extends StatefulWidget {
  const SplashScreenWithAccessibility({super.key});

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
    final access = Provider.of<AccessibilityProvider>(context, listen: false);
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    // Load saved settings if user is logged in
    if (FirebaseAuth.instance.currentUser != null) {
      await access.loadSettings();
    }

    // Always apply whatever theme string is current (default is "light")
    theme.setTheme(access.theme);

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WebAuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

/// Decides login vs dashboard
class WebAuthWrapper extends StatelessWidget {
  const WebAuthWrapper({super.key});

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

/// Routes based on Firestore role
class DashboardRouter extends StatelessWidget {
  const DashboardRouter({super.key});

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