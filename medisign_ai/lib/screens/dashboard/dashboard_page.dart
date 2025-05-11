

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccessibilityProvider>(context, listen: false).loadSettings();
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
        userProfileUrl = user.photoURL ?? '';
        if (doc.exists) {
          final data = doc.data()!;
          userDisplayName = data['displayName']
              ?? data['name']
              ?? user.displayName
              ?? user.email?.split('@').first
              ?? 'Patient';
          if ((data['photoUrl'] ?? '').isNotEmpty) {
            userProfileUrl = data['photoUrl'];
          }
        } else {
          userDisplayName = user.displayName
              ?? user.email?.split('@').first
              ?? 'Patient';
        }
      });
    } catch (_) {
      if (_isDisposed) return;
      setState(() {
        userDisplayName = user.displayName ?? user.email?.split('@').first ?? 'Patient';
        userEmail = user.email ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AccessibilityProvider>(context);
    final primary = const Color(0xFFF45B69);

    return Scaffold(
      drawer: _buildDrawer(ap, primary),
      appBar: AppBar(
        title: Text('Dashboard', style: ap.getTextStyle(fontWeight: FontWeight.bold, sizeMultiplier: 1.2)),
        backgroundColor: primary,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: ap.fontSize * 1.2),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccessibilitySettingsPage()),
            ),
          ),
          IconButton(
            icon: CircleAvatar(
              radius: ap.fontSize * 0.9,
              backgroundColor: Colors.white,
              backgroundImage: userProfileUrl.isNotEmpty ? NetworkImage(userProfileUrl) : null,
              child: userProfileUrl.isEmpty
                  ? Icon(Icons.person, color: primary, size: ap.fontSize * 1.2)
                  : null,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            ).then((_) => _loadUserProfile()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ─── Header: Six Quick-Action Cards ─────────────────────────
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _quickCard(ap, Icons.sign_language, 'Translate', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SignTranslatePage()));
                  }),
                  _quickCard(ap, Icons.chat, 'Chat', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationModePage()));
                  }),
                  _quickCard(ap, Icons.favorite, 'Check-In', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthCheckinPage()));
                  }),
                  _quickCard(ap, Icons.video_call, 'Telemed', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TelemedicinePage()));
                  }),
                  _quickCard(ap, Icons.school, 'Learn', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningGamifiedPage()));
                  }),
                  _quickCard(ap, Icons.local_hospital, 'Services', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalGuidePage()));
                  }),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Progress Tracking ───────────────────────────────────────
              _sectionCard(
                ap,
                primary,
                'Progress Tracking',
                _buildProgressChart(ap),
              ),
              const SizedBox(height: 16),

              // ─── Recent Interactions ─────────────────────────────────────
              _sectionCard(
                ap,
                primary,
                'Recent Interactions',
                _buildRecentInteractions(ap),
              ),
              const SizedBox(height: 16),

              // ─── Medication Overview ────────────────────────────────────
              _sectionCard(
                ap,
                primary,
                'Medication Overview',
                _buildMedicationOverview(ap),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickCard(AccessibilityProvider ap, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: ap.fontSize * 1.8, color: Colors.black54),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: ap.getTextStyle(sizeMultiplier: 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(AccessibilityProvider ap, Color primary, String title, Widget child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ap.getTextStyle(fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart(AccessibilityProvider ap) {
    Widget bar(String label, int pct, Color c) {
      return Expanded(
        child: Column(
          children: [
            RotatedBox(
              quarterTurns: 3,
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(c),
                minHeight: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text('$pct%', style: ap.getTextStyle(fontWeight: FontWeight.bold)),
            Text(label, style: ap.getTextStyle(sizeMultiplier: 0.8)),
          ],
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: Row(
        children: [
          bar('Translation', 85, Colors.blue),
          const SizedBox(width: 12),
          bar('Sign Language', 70, Colors.green),
          const SizedBox(width: 12),
          bar('Practice', 90, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildRecentInteractions(AccessibilityProvider ap) {
    final items = [
      {'time': '10:30 AM', 'type': 'Translation', 'status': 'Completed'},
      {'time': '2:15 PM', 'type': 'Consultation', 'status': 'Upcoming'},
      {'time': 'Yesterday', 'type': 'Practice', 'status': 'Completed'},
    ];

    return Column(
      children: items.map((it) {
        final color = it['status'] == 'Completed' ? Colors.green : Colors.orange;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: color.withOpacity(0.2), child: Icon(Icons.history, color: color, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text('${it['type']} · ${it['time']}', style: ap.getTextStyle())),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(it['status']!, style: ap.getTextStyle(color: color, sizeMultiplier: 0.8)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMedicationOverview(AccessibilityProvider ap) {
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
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: color.withOpacity(0.2), child: Icon(Icons.medication, color: color, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text('${m['name']} · ${m['time']}', style: ap.getTextStyle())),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(m['status']!, style: ap.getTextStyle(color: color, sizeMultiplier: 0.8)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDrawer(AccessibilityProvider ap, Color primary) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: ap.fontSize * 1.5,
                  backgroundColor: Colors.white,
                  backgroundImage: userProfileUrl.isNotEmpty ? NetworkImage(userProfileUrl) : null,
                  child: userProfileUrl.isEmpty
                      ? Icon(Icons.person, size: ap.fontSize * 1.5, color: primary)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(userDisplayName, style: ap.getTextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(userEmail, style: ap.getTextStyle(color: Colors.white70, sizeMultiplier: 0.8)),
              ],
            ),
          ),
          _drawerItem(ap, Icons.sign_language, 'Translate', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SignTranslatePage()));
          }),
          _drawerItem(ap, Icons.chat, 'Conversation', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationModePage()));
          }),
          _drawerItem(ap, Icons.favorite, 'Health Check-In', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthCheckinPage()));
          }),
          _drawerItem(ap, Icons.video_call, 'Telemedicine', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TelemedicinePage()));
          }),
          _drawerItem(ap, Icons.school, 'Learn & Practice', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningGamifiedPage()));
          }),
          _drawerItem(ap, Icons.local_hospital, 'Hospital Services', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalGuidePage()));
          }),
          _drawerItem(ap, Icons.settings, 'Accessibility Settings', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilitySettingsPage()));
          }),
          _drawerItem(ap, Icons.logout, 'Logout', _handleLogout),
        ],
      ),
    );
  }

  ListTile _drawerItem(AccessibilityProvider ap, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: ap.getTextStyle()),
      onTap: onTap,
    );
  }

  Future<void> _handleLogout() async {
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout error: $e')));
      }
    }
  }
}