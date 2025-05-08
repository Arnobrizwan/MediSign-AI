import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 

// Import your pages
import 'screens/login/login_page.dart';
import 'screens/login/registration_page.dart';
import 'screens/login/forgot_password_page.dart';
import 'screens/dashboard/dashboard_page.dart';
import 'screens/sign_translate/sign_translate_page.dart';
import 'screens/conversation_mode/conversation_mode_page.dart';
import 'screens/accessibility_settings/accessibility_settings_page.dart';
import 'screens/transcript_history/transcript_history_page.dart';
import 'screens/tutorial_support/tutorial_support_page.dart';
// import 'screens/braille_interaction/braille_interaction_page.dart';
import 'screens/health_checkin/health_checkin_page.dart';
import 'screens/patient_locator/patient_locator_page.dart';
import 'screens/telemedicine/telemedicine_page.dart';
import 'screens/learning_gamified/learning_gamified_page.dart';
// import 'screens/emotion_mood/emotion_mood_page.dart';
import 'screens/family_portal/family_portal_page.dart';
import 'screens/admin_dashboard/admin_dashboard_page.dart';
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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/registration': (context) => const RegistrationPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/dashboard': (context) => const PatientDashboardPage(),
        '/sign_translate': (context) => const SignTranslatePage(),
        '/conversation_mode': (context) => const ConversationModePage(),
        '/accessibility_settings': (context) => const AccessibilitySettingsPage(),
        '/transcript_history': (context) => const TranscriptHistoryPage(),
        '/tutorial_support': (context) => const TutorialSupportPage(),
        // '/braille_interaction': (context) => const BrailleInteractionPage(),
        '/health_checkin': (context) => const HealthCheckinPage(),
        '/patient_locator': (context) => const PatientLocatorPage(),
        '/telemedicine': (context) => const TelemedicinePage(),
        '/learning_gamified': (context) => const LearningGamifiedPage(),
        // '/emotion_mood': (context) => const EmotionMoodPage(),
        '/family_portal': (context) => const FamilyPortalPage(),
        '/admin_dashboard': (context) => const AdminDashboardPage(),
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