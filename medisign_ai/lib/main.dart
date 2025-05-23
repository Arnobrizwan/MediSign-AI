import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

import 'providers/theme_provider.dart';
import 'providers/accessibility_provider.dart';

//import 'screens/braille_interaction/braille_interaction_page.dart'as braille;

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
import 'providers/emotion_mood_detection_manager.dart';
// ─── doctor dashboards ──────────────────────────────────────────────────
import 'screens/doctor/doctor_dashboard_page.dart';
import 'screens/doctor/doctor_appointments_page.dart';
import 'screens/doctor/doctor_telemedicine_page.dart';
import 'screens/doctor/doctor_conversation_page.dart';
import 'screens/doctor/doctor_medical_records_page.dart';
import 'screens/doctor/doctor_prescriptions_page.dart';
import 'screens/ambulance/ambulance_dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Keep users signed in on Web
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (_) {}

  // Initialize emotion detection manager
  final emotionManager = EmotionMoodDetectionManager();
  await emotionManager.initialize();

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

// Custom Navigator observer to adapt emotion detection based on current page
class EmotionAwareNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateEmotionDetection(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _updateEmotionDetection(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _updateEmotionDetection(previousRoute);
    }
  }

  // Helper to determine if we should use camera detection based on route
  void _updateEmotionDetection(Route<dynamic> route) {
    final routeName = route.settings.name;
    final context = navigator?.context;
    if (context == null) return;

    // List of camera-active routes that should use enhanced monitoring
    final cameraActiveRoutes = [
      '/sign_translate',
      '/conversation_mode',
      '/telemedicine',
    ];

    // List of routes that might benefit from text analysis
    final textAnalysisRoutes = [
      '/health_checkin',
    ];

    final emotionManager = EmotionMoodDetectionManager();
    
    // If route uses camera or needs text analysis
    if (cameraActiveRoutes.contains(routeName)) {
      // Start full monitoring with camera
      emotionManager.startMonitoring(context);
    } else if (textAnalysisRoutes.contains(routeName)) {
      // Keep monitoring active but optimize for text input
      emotionManager.startMonitoring(context, reducedFrequency: true);
    } else {
      // For other routes, we can still keep basic monitoring
      emotionManager.startMonitoring(context, reducedFrequency: true);
    }
  }
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
        '/editProfile': (_) => const EditProfilePage(),
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
        // ─── doctor ─────────────────────────────────────────────────────────
  '/doctor/dashboard':      (_) => const DoctorDashboardPage(),
  '/doctor/appointments':   (_) => const DoctorAppointmentsPage(),
  '/doctor/telemedicine':   (_) => const DoctorTelemedicinePage(),
  '/doctor/medical_records':(_) => const DoctorMedicalRecordsPage(),
  '/doctor/prescriptions':  (_) => const DoctorPrescriptionsPage(),
  // for conversation we need to pass the doctor’s name as an argument:
  '/doctor/conversation': (ctx) {
    final doctorName = ModalRoute.of(ctx)!.settings.arguments as String;
    return DoctorConversationPage(doctorName: doctorName);
  },

  // ─── ambulance ───────────────────────────────────────────────────────
  '/ambulance_dashboard': (_) => const AmbulanceDashboardPage(),
        '/hospital_guide': (_) => const HospitalGuidePage(),
        '/billing': (ctx) {
          // Grab the current user's ID (or displayName) however you like:
          final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
          return BillingPage(patientId: uid);
        },
      },
      navigatorObservers: [
        // Add custom navigator observer for emotion detection
        EmotionAwareNavigatorObserver(),
      ],
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const LoginPage();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If we found a users/{uid} doc, try its role
        if (snap.hasData && snap.data!.exists) {
          final rawRole = (snap.data!.data() as Map<String, dynamic>)['role'] as String? ?? '';
          print('🎯 rawRole from Firestore = "$rawRole"');
          final role = rawRole.trim().toLowerCase();

          switch (role) {
            case 'admin':
              return const AdminDashboardPage();
            case 'doctor':
              return const DoctorDashboardPage();
            case 'ambulance':
              return const AmbulanceDashboardPage();
            default:
              return const PatientDashboardPage();
          }
        }

        // Otherwise, maybe this user is stored under ambulanceStaff
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('ambulanceStaff').doc(uid).get(),
          builder: (ctx2, snap2) {
            if (snap2.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap2.hasData && snap2.data!.exists) {
              // Found them as ambulance staff
              return const AmbulanceDashboardPage();
            }
            // fallback to patient
            return const PatientDashboardPage();
          },
        );
      },
    );
  }
}