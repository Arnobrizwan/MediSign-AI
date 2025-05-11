import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/accessibility_provider.dart';
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
  
  runApp(
    // Wrap the app with providers
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
        // Apply theme changes whenever accessibility theme changes
        accessibilityProvider.addListener(() {
          themeProvider.setTheme(accessibilityProvider.theme);
        });

        return MaterialApp(
          title: 'MediSign AI',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          builder: (context, child) {
            // Apply global text scaling based on accessibility settings
            final fontSize = accessibilityProvider.fontSize;
            final baselineSize = 16.0;
            final scale = fontSize / baselineSize;
            
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: scale,
              ),
              child: child!,
            );
          },
          // Choose either SplashScreen or WebAuthWrapper as the home
          home: const SplashScreenWithAccessibility(), // Modified splash screen
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
      },
    );
  }
}

// Modified splash screen that loads accessibility settings
class SplashScreenWithAccessibility extends StatefulWidget {
  const SplashScreenWithAccessibility({super.key});

  @override
  State<SplashScreenWithAccessibility> createState() => _SplashScreenWithAccessibilityState();
}

class _SplashScreenWithAccessibilityState extends State<SplashScreenWithAccessibility> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load accessibility settings early
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    // Check if user is logged in and load their settings
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await accessibilityProvider.loadSettings();
        themeProvider.setTheme(accessibilityProvider.theme);
      } catch (e) {
        print('Error loading accessibility settings: $e');
        // Continue with default settings
      }
    }
    
    // Navigate to appropriate screen after a brief delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WebAuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen(); // Your existing splash screen
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
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF45B69),
              ),
            ),
          );
        }
        
        // User logged in
        if (snapshot.hasData && snapshot.data != null) {
          // Load accessibility settings for logged-in user
          _loadUserAccessibilitySettings(context, snapshot.data!);
          return const DashboardRouter();
        }
        
        // User not logged in - use default accessibility settings
        return const LoginPage();
      },
    );
  }

  void _loadUserAccessibilitySettings(BuildContext context, User user) async {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    try {
      await accessibilityProvider.loadSettings();
      themeProvider.setTheme(accessibilityProvider.theme);
    } catch (e) {
      print('Error loading user accessibility settings: $e');
    }
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
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(
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