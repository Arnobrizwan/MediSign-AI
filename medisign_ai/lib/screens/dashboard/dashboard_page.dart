

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:provider/provider.dart';
// import '../../providers/accessibility_provider.dart';

// import '../sign_translate/sign_translate_page.dart';
// import '../conversation_mode/conversation_mode_page.dart';
// import '../accessibility_settings/accessibility_settings_page.dart';
// import '../transcript_history/transcript_history_page.dart';
// import '../tutorial_support/tutorial_support_page.dart';
// import '../health_checkin/health_checkin_page.dart';
// import '../patient_locator/patient_locator_page.dart';
// import '../telemedicine/telemedicine_page.dart';
// import '../learning_gamified/learning_gamified_page.dart';
// import '../family_portal/family_portal_page.dart';
// import '../appointment_center/appointment_center_page.dart';
// import '../medical_records/medical_records_page.dart';
// import '../prescription_management/prescriptions_page.dart';
// import '../hospital_guide/hospital_guide_page.dart';
// import '../billing/billing_page.dart';
// import '../login/edit_profile_page.dart';
// import '../login/login_page.dart';

// class PatientDashboardPage extends StatefulWidget {
//   const PatientDashboardPage({super.key});

//   @override
//   State<PatientDashboardPage> createState() => _PatientDashboardPageState();
// }

// class _PatientDashboardPageState extends State<PatientDashboardPage> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String userDisplayName = '';
//   String userEmail = '';
//   String userProfileUrl = '';
//   bool _isDisposed = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserProfile();
//     // Load accessibility settings when dashboard loads
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadAccessibilitySettings();
//     });
//   }

//   @override
//   void dispose() {
//     _isDisposed = true;
//     super.dispose();
//   }

//   Future<void> _loadAccessibilitySettings() async {
//     final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
//     final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
//     await accessibilityProvider.loadSettings();
//     themeProvider.setTheme(accessibilityProvider.theme);
//   }

//   Future<void> _loadUserProfile() async {
//     if (_isDisposed) return;
    
//     final user = _auth.currentUser;
//     if (user == null) return;

//     try {
//       final doc = await _firestore.collection('users').doc(user.uid).get();
      
//       if (!_isDisposed) {
//         setState(() {
//           userEmail = user.email ?? '';
//           userProfileUrl = user.photoURL ?? '';
          
//           if (doc.exists) {
//             final data = doc.data()!;
//             userDisplayName = data['displayName'] ?? 
//                              data['name'] ?? 
//                              user.displayName ?? 
//                              user.email?.split('@')[0] ?? 
//                              'Patient';
//             // Update profile URL from Firestore if available
//             if (data['photoUrl'] != null && data['photoUrl'].isNotEmpty) {
//               userProfileUrl = data['photoUrl'];
//             }
//           } else {
//             userDisplayName = user.displayName ?? 
//                              user.email?.split('@')[0] ?? 
//                              'Patient';
//           }
//         });
//       }
//     } catch (e) {
//       print('Error loading user profile: $e');
//       if (!_isDisposed) {
//         setState(() {
//           userDisplayName = user?.displayName ?? 
//                            user?.email?.split('@')[0] ?? 
//                            'Patient';
//           userEmail = user?.email ?? '';
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
//     final primaryColor = const Color(0xFFF45B69);
//     final baseFontSize = accessibilityProvider.fontSize;

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       drawer: _buildDrawer(),
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
//         foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
//         title: Text(
//           'Welcome, $userDisplayName',
//           style: accessibilityProvider.getTextStyle(sizeMultiplier: 1.25),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const AccessibilitySettingsPage(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _loadUserProfile,
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // User Profile Header
//               Card(
//                 elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 color: Theme.of(context).cardColor,
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Row(
//                     children: [
//                       _buildProfileAvatar(),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               userDisplayName,
//                               style: accessibilityProvider.getTextStyle(
//                                 sizeMultiplier: 1.25,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               userEmail,
//                               style: accessibilityProvider.getTextStyle(
//                                 sizeMultiplier: 0.87,
//                                 color: Colors.grey.shade600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.edit),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const EditProfilePage(),
//                             ),
//                           ).then((_) {
//                             if (!_isDisposed) {
//                               _loadUserProfile();
//                             }
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
              
//               // Quick Actions
//               Text(
//                 'Quick Actions',
//                 style: accessibilityProvider.getTextStyle(
//                   sizeMultiplier: 1.25,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               GridView.count(
//                 crossAxisCount: 3,
//                 crossAxisSpacing: 12,
//                 mainAxisSpacing: 12,
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 childAspectRatio: 1.1,
//                 children: [
//                   _buildQuickActionCard(
//                     'Translate Sign Language',
//                     Icons.sign_language,
//                     Colors.blue,
//                     () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignTranslatePage())),
//                   ),
//                   _buildQuickActionCard(
//                     'Patient-Doctor\nConversation',
//                     Icons.chat,
//                     Colors.green,
//                     () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationModePage())),
//                   ),
//                   _buildQuickActionCard(
//                     'AI Health\nCheck-In',
//                     Icons.favorite,
//                     Colors.red,
//                     () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthCheckinPage())),
//                   ),
//                   _buildQuickActionCard(
//                     'Telemedicine',
//                     Icons.video_call,
//                     Colors.orange,
//                     () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelemedicinePage())),
//                   ),
//                   _buildQuickActionCard(
//                     'Learn &\nPractice',
//                     Icons.school,
//                     Colors.purple,
//                     () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningGamifiedPage())),
//                   ),
//                   _buildQuickActionCard(
//                     'Hospital\nServices',
//                     Icons.local_hospital,
//                     primaryColor,
//                     () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalGuidePage())),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
              
//               // Progress Tracking
//               _buildChartCard('Progress Tracking', _buildProgressChart()),
              
//               const SizedBox(height: 16),
              
//               // Recent Interactions
//               _buildChartCard('Recent Interactions', _buildRecentInteractions()),
              
//               const SizedBox(height: 16),
              
//               // Medication Overview
//               _buildChartCard('Medication Overview', _buildMedicationOverview()),
              
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
//     final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
//     final baseFontSize = accessibilityProvider.fontSize;

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: color.withOpacity(0.3),
//             width: accessibilityProvider.highContrast ? 2 : 1,
//           ),
//         ),
//         padding: EdgeInsets.all(baseFontSize * 0.75),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: EdgeInsets.all(baseFontSize * 0.5),
//               decoration: BoxDecoration(
//                 color: color,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 icon, 
//                 color: Colors.white, 
//                 size: baseFontSize * 1.5,
//               ),
//             ),
//             SizedBox(height: baseFontSize * 0.5),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: accessibilityProvider.getTextStyle(
//                 sizeMultiplier: 0.75,
//                 fontWeight: FontWeight.w500,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildChartCard(String title, Widget chart) {
//     final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
//     final primaryColor = const Color(0xFFF45B69);

//     return Card(
//       elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       color: Theme.of(context).cardColor,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: accessibilityProvider.getTextStyle(
//                 sizeMultiplier: 1.0,
//                 fontWeight: FontWeight.bold,
//                 color: primaryColor,
//               ),
//             ),
//             const SizedBox(height: 12),
//             chart,
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProgressChart() {
//     return SizedBox(
//       height: 100,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           Expanded(child: _buildProgressBar('Translation', 85, Colors.blue)),
//           const SizedBox(width: 8),
//           Expanded(child: _buildProgressBar('Sign Language', 70, Colors.green)),
//           const SizedBox(width: 8),
//           Expanded(child: _buildProgressBar('Practice', 90, Colors.purple)),
//         ],
//       ),
//     );
//   }

//   Widget _buildProgressBar(String label, int percentage, Color color) {
//     final accessibilityProvider = Provider.of<AccessibilityProvider>(context);

//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         SizedBox(
//           height: 60,
//           width: 20,
//           child: RotatedBox(
//             quarterTurns: 3,
//             child: LinearProgressIndicator(
//               value: percentage / 100,
//               backgroundColor: Colors.grey.shade200,
//               valueColor: AlwaysStoppedAnimation<Color>(color),
//               minHeight: 20,
//             ),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           '$percentage%',
//           style: accessibilityProvider.getTextStyle(
//             fontWeight: FontWeight.bold, 
//             sizeMultiplier: 0.75,
//           ),
//         ),
//         Text(
//           label,
//           style: accessibilityProvider.getTextStyle(sizeMultiplier: 0.625),
//           textAlign: TextAlign.center,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ],
//     );
//   }

//   Widget _buildRecentInteractions() {
//     final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    
//     final interactions = [
//       {'time': '10:30 AM', 'type': 'Translation Session', 'status': 'Completed'},
//       {'time': '2:15 PM', 'type': 'Doctor Consultation', 'status': 'Upcoming'},
//       {'time': 'Yesterday', 'type': 'Sign Practice', 'status': 'Completed'},
//     ];

//     return Column(
//       children: interactions.map((item) {
//         Color statusColor = item['status'] == 'Completed' 
//             ? Colors.green 
//             : item['status'] == 'Upcoming' 
//                 ? Colors.orange 
//                 : Colors.grey;
                
//         return Padding(
//           padding: const EdgeInsets.only(bottom: 12),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(Icons.history, color: statusColor, size: 20),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       item['type']!,
//                       style: accessibilityProvider.getTextStyle(
//                         sizeMultiplier: 0.87,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       item['time']!,
//                       style: accessibilityProvider.getTextStyle(
//                         sizeMultiplier: 0.75,
//                         color: Colors.grey.shade600,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Container(
//                 constraints: const BoxConstraints(minWidth: 60),
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   item['status']!,
//                   style: accessibilityProvider.getTextStyle(
//                     sizeMultiplier: 0.68,
//                     color: statusColor,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildMedicationOverview() {
//     final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    
//     final medications = [
//       {'name': 'Medication A', 'time': '8:00 AM', 'status': 'Taken'},
//       {'name': 'Medication B', 'time': '2:00 PM', 'status': 'Pending'},
//       {'name': 'Medication C', 'time': '8:00 PM', 'status': 'Upcoming'},
//     ];

//     return Column(
//       children: medications.map((med) {
//         Color statusColor = med['status'] == 'Taken' 
//             ? Colors.green 
//             : med['status'] == 'Pending' 
//                 ? Colors.orange 
//                 : Colors.grey;
                
//         return Padding(
//           padding: const EdgeInsets.only(bottom: 12),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(Icons.medication, color: statusColor, size: 20),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       med['name']!,
//                       style: accessibilityProvider.getTextStyle(
//                         sizeMultiplier: 0.87,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       'Time: ${med['time']}',
//                       style: accessibilityProvider.getTextStyle(
//                         sizeMultiplier: 0.75,
//                         color: Colors.grey.shade600,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Container(
//                 constraints: const BoxConstraints(minWidth: 60),
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   med['status']!,
//                   style: accessibilityProvider.getTextStyle(
//                     sizeMultiplier: 0.68,
//                     color: statusColor,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildProfileAvatar() {
//     final primaryColor = const Color(0xFFF45B69);
    
//     if (userProfileUrl.isNotEmpty) {
//       return CircleAvatar(
//         radius: 35,
//         backgroundColor: Colors.grey.shade300,
//         child: ClipOval(
//           child: Image.network(
//             userProfileUrl,
//             width: 70,
//             height: 70,
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) {
//               return Icon(Icons.person, size: 35, color: primaryColor);
//             },
//           ),
//         ),
//       );
//     } else {
//       return CircleAvatar(
//         radius: 35,
//         backgroundColor: primaryColor.withOpacity(0.1),
//         child: Icon(Icons.person, size: 35, color: primaryColor),
//       );
//     }
//   }

//   Widget _buildDrawer() {
//     final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
//     final primaryColor = const Color(0xFFF45B69);

//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(color: primaryColor),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildProfileAvatar(),
//                 const SizedBox(height: 8),
//                 Text(
//                   userDisplayName,
//                   style: accessibilityProvider.getTextStyle(
//                     sizeMultiplier: 1.12,
//                     color: Colors.white,
//                   ),
//                 ),
//                 Text(
//                   userEmail,
//                   style: accessibilityProvider.getTextStyle(
//                     sizeMultiplier: 0.87,
//                     color: Colors.white70,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           _buildDrawerItem(
//             icon: Icons.translate,
//             title: 'Translate Sign Language',
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const SignTranslatePage()));
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.chat,
//             title: 'Patient-Doctor Conversation',
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationModePage()));
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.history,
//             title: 'Medical History',
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalRecordsPage()));
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.favorite,
//             title: 'AI Health Check-In',
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthCheckinPage()));
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.video_call,
//             title: 'Telemedicine',
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const TelemedicinePage()));
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.school,
//             title: 'Learn & Practice',
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningGamifiedPage()));
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.local_hospital,
//             title: 'Hospital Services',
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalGuidePage()));
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.help,
//             title: 'Tutorial & Support',
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialSupportPage()));
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.people,
//             title: 'Family Portal',
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyPortalPage()));
//             },
//           ),
//           const Divider(),
//           _buildDrawerItem(
//             icon: Icons.settings,
//             title: 'Accessibility Settings',
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilitySettingsPage()));
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.logout,
//             title: 'Logout',
//             onTap: _handleLogout,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawerItem({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     final accessibilityProvider = Provider.of<AccessibilityProvider>(context);

//     return ListTile(
//       leading: Icon(icon),
//       title: Text(
//         title,
//         style: accessibilityProvider.getTextStyle(),
//       ),
//       onTap: onTap,
//     );
//   }
  
//   Future<void> _handleLogout() async {
//     // Close the drawer first
//     Navigator.pop(context);
    
//     // Show loading dialog
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(
//         child: CircularProgressIndicator(
//           color: Color(0xFFF45B69),
//         ),
//       ),
//     );
    
//     try {
//       // Sign out from Firebase
//       await FirebaseAuth.instance.signOut();
      
//       // Close loading dialog
//       if (mounted) Navigator.pop(context);
      
//       // Navigate to login page
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const LoginPage()),
//         );
//       }
//     } catch (e) {
//       // Close loading dialog
//       if (mounted) Navigator.pop(context);
      
//       // Show error
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error signing out: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../providers/accessibility_provider.dart';
import '../../providers/theme_provider.dart';

import '../sign_translate/sign_translate_page.dart';
import '../conversation_mode/conversation_mode_page.dart';
import '../accessibility_settings/accessibility_settings_page.dart';
import '../transcript_history/transcript_history_page.dart';
import '../tutorial_support/tutorial_support_page.dart';
import '../health_checkin/health_checkin_page.dart';
import '../patient_locator/patient_locator_page.dart';
import '../telemedicine/telemedicine_page.dart';
import '../learning_gamified/learning_gamified_page.dart';
import '../family_portal/family_portal_page.dart';
import '../appointment_center/appointment_center_page.dart';
import '../medical_records/medical_records_page.dart';
import '../prescription_management/prescriptions_page.dart';
import '../hospital_guide/hospital_guide_page.dart';
import '../billing/billing_page.dart';
import '../login/edit_profile_page.dart';
import '../login/login_page.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({Key? key}) : super(key: key);

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String userDisplayName = '';
  String userEmail = '';
  String userProfileUrl = '';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // load accessibility & theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final acc = Provider.of<AccessibilityProvider>(context, listen: false);
      final theme = Provider.of<ThemeProvider>(context, listen: false);
      acc.loadSettings().then((_) => theme.setTheme(acc.theme));
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (_isDisposed) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (_isDisposed) return;
      setState(() {
        userEmail = user.email ?? '';
        userProfileUrl = doc.data()?['photoUrl'] as String? ?? user.photoURL ?? '';
        userDisplayName = doc.data()?['displayName'] as String? ??
            user.displayName ??
            user.email?.split('@')[0] ??
            'Patient';
      });
    } catch (_) {
      if (_isDisposed) return;
      setState(() {
        userDisplayName = user.displayName ?? user.email?.split('@')[0] ?? 'Patient';
        userEmail = user.email ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final acc = Provider.of<AccessibilityProvider>(context);
    final baseFont = acc.fontSize;
    final primaryColor = const Color(0xFFF45B69);

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Text('Dashboard', style: acc.getTextStyle(sizeMultiplier: 1.25)),
        centerTitle: true,
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccessibilitySettingsPage()),
            ),
          ),
          // Small user avatar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              ),
              child: CircleAvatar(
                radius: baseFont * 0.9,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    userProfileUrl.isNotEmpty ? NetworkImage(userProfileUrl) : null,
                child: userProfileUrl.isEmpty
                    ? Icon(Icons.person, color: primaryColor, size: baseFont)
                    : null,
              ),
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // — Progress Tracking —
              _buildChartCard('Progress Tracking', _buildProgressChart()),

              const SizedBox(height: 16),

              // — Recent Interactions —
              _buildChartCard('Recent Interactions', _buildRecentInteractions()),

              const SizedBox(height: 16),

              // — Medication Overview —
              _buildChartCard('Medication Overview', _buildMedicationOverview()),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    final acc = Provider.of<AccessibilityProvider>(context);
    final primaryColor = const Color(0xFFF45B69);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: acc.getTextStyle(
                    fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 12),
            chart,
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    return SizedBox(
      height: 100,
      child: Row(
        children: [
          Expanded(child: _buildProgressBar('Translation', 85, Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _buildProgressBar('Sign Language', 70, Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _buildProgressBar('Practice', 90, Colors.purple)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int pct, Color c) {
    final acc = Provider.of<AccessibilityProvider>(context);
    return Column(
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(c),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('$pct%', style: acc.getTextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: acc.getTextStyle(sizeMultiplier: 0.75)),
      ],
    );
  }

  Widget _buildRecentInteractions() {
    final acc = Provider.of<AccessibilityProvider>(context);
    final data = [
      {'time': '10:30 AM', 'type': 'Translation Session', 'status': 'Completed'},
      {'time': '2:15 PM', 'type': 'Doctor Consultation', 'status': 'Upcoming'},
      {'time': 'Yesterday', 'type': 'Sign Practice', 'status': 'Completed'},
    ];

    return Column(
      children: data.map((item) {
        final color = item['status'] == 'Completed'
            ? Colors.green
            : item['status'] == 'Upcoming'
                ? Colors.orange
                : Colors.grey;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(Icons.history, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['type']!, style: acc.getTextStyle()),
                    const SizedBox(height: 2),
                    Text(item['time']!,
                        style: acc.getTextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Text(item['status']!, style: acc.getTextStyle(color: color)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMedicationOverview() {
    final acc = Provider.of<AccessibilityProvider>(context);
    final meds = [
      {'name': 'Medication A', 'time': '8:00 AM', 'status': 'Taken'},
      {'name': 'Medication B', 'time': '2:00 PM', 'status': 'Pending'},
      {'name': 'Medication C', 'time': '8:00 PM', 'status': 'Upcoming'},
    ];

    return Column(
      children: meds.map((m) {
        final color = m['status'] == 'Taken'
            ? Colors.green
            : m['status'] == 'Pending'
                ? Colors.orange
                : Colors.grey;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(Icons.medication, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['name']!, style: acc.getTextStyle()),
                    const SizedBox(height: 2),
                    Text('Time: ${m['time']}',
                        style: acc.getTextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Text(m['status']!, style: acc.getTextStyle(color: color)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDrawer() {
    final acc = Provider.of<AccessibilityProvider>(context);
    final primaryColor = const Color(0xFFF45B69);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  backgroundImage: userProfileUrl.isNotEmpty
                      ? NetworkImage(userProfileUrl)
                      : null,
                  child: userProfileUrl.isEmpty
                      ? Icon(Icons.person, color: primaryColor)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(userDisplayName,
                    style:
                        acc.getTextStyle(sizeMultiplier: 1.2, color: Colors.white)),
                Text(userEmail,
                    style:
                        acc.getTextStyle(sizeMultiplier: 0.9, color: Colors.white70)),
              ],
            ),
          ),
          _drawerItem(Icons.translate, 'Translate Sign Language',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignTranslatePage()))),
          _drawerItem(Icons.chat, 'Patient-Doctor Conversation',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationModePage()))),
          _drawerItem(Icons.history, 'Medical History',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalRecordsPage()))),
          _drawerItem(Icons.favorite, 'AI Health Check-In',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthCheckinPage()))),
          _drawerItem(Icons.video_call, 'Telemedicine',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelemedicinePage()))),
          _drawerItem(Icons.school, 'Learn & Practice',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningGamifiedPage()))),
          _drawerItem(Icons.local_hospital, 'Hospital Services',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalGuidePage()))),
          _drawerItem(Icons.help, 'Tutorial & Support',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialSupportPage()))),
          _drawerItem(Icons.people, 'Family Portal',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyPortalPage()))),
          const Divider(),
          _drawerItem(Icons.settings, 'Accessibility Settings',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilitySettingsPage()))),
          _drawerItem(Icons.logout, 'Logout', _handleLogout),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String label, VoidCallback onTap) {
    final acc = Provider.of<AccessibilityProvider>(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: acc.getTextStyle()),
      onTap: onTap,
    );
  }

  Future<void> _handleLogout() async {
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFF45B69))),
    );
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pop(context); // close dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}