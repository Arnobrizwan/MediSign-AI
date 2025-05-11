// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
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
//   final Color primaryColor = const Color(0xFFF45B69);
//   bool _isDisposed = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserProfile();
//   }

//   @override
//   void dispose() {
//     _isDisposed = true;
//     super.dispose();
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

//   Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: color.withOpacity(0.3)),
//         ),
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: color,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, color: Colors.white, size: 24),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 12,
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
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 16,
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
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//         ),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 10),
//           textAlign: TextAlign.center,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ],
//     );
//   }

//   Widget _buildRecentInteractions() {
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
//                       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       item['time']!,
//                       style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
//                   style: TextStyle(color: statusColor, fontSize: 11),
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
//                       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       'Time: ${med['time']}',
//                       style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
//                   style: TextStyle(color: statusColor, fontSize: 11),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       drawer: _buildDrawer(),
//       appBar: AppBar(
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.white,
//         title: Text('Welcome, $userDisplayName'),
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
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // User Profile Header
//               Card(
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
//                               style: const TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               userEmail,
//                               style: TextStyle(
//                                 color: Colors.grey.shade600,
//                                 fontSize: 14,
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
//               const Text(
//                 'Quick Actions',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

//   Widget _buildProfileAvatar() {
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
//                   style: const TextStyle(color: Colors.white, fontSize: 18),
//                 ),
//                 Text(
//                   userEmail,
//                   style: const TextStyle(color: Colors.white70, fontSize: 14),
//                 ),
//               ],
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.translate),
//             title: const Text('Translate Sign Language'),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const SignTranslatePage()));
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.chat),
//             title: const Text('Patient-Doctor Conversation'),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationModePage()));
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.history),
//             title: const Text('Medical History'),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalRecordsPage()));
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.favorite),
//             title: const Text('AI Health Check-In'),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthCheckinPage()));
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.video_call),
//             title: const Text('Telemedicine'),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const TelemedicinePage()));
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.school),
//             title: const Text('Learn & Practice'),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningGamifiedPage()));
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.local_hospital),
//             title: const Text('Hospital Services'),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalGuidePage()));
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.help),
//             title: const Text('Tutorial & Support'),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialSupportPage()));
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.people),
//             title: const Text('Family Portal'),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyPortalPage()));
//             },
//           ),
//           const Divider(),
//           ListTile(
//             leading: const Icon(Icons.settings),
//             title: const Text('Accessibility Settings'),
//             onTap: () {
//               Navigator.pop(context);
//               Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilitySettingsPage()));
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.logout),
//             title: const Text('Logout'),
//             onTap: () => _handleLogout(),
//           ),
//         ],
//       ),
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
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userDisplayName = '';
  String userEmail = '';
  String userProfileUrl = '';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    // Load accessibility settings when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAccessibilitySettings();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadAccessibilitySettings() async {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    await accessibilityProvider.loadSettings();
    themeProvider.setTheme(accessibilityProvider.theme);
  }

  Future<void> _loadUserProfile() async {
    if (_isDisposed) return;
    
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!_isDisposed) {
        setState(() {
          userEmail = user.email ?? '';
          userProfileUrl = user.photoURL ?? '';
          
          if (doc.exists) {
            final data = doc.data()!;
            userDisplayName = data['displayName'] ?? 
                             data['name'] ?? 
                             user.displayName ?? 
                             user.email?.split('@')[0] ?? 
                             'Patient';
            // Update profile URL from Firestore if available
            if (data['photoUrl'] != null && data['photoUrl'].isNotEmpty) {
              userProfileUrl = data['photoUrl'];
            }
          } else {
            userDisplayName = user.displayName ?? 
                             user.email?.split('@')[0] ?? 
                             'Patient';
          }
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (!_isDisposed) {
        setState(() {
          userDisplayName = user?.displayName ?? 
                           user?.email?.split('@')[0] ?? 
                           'Patient';
          userEmail = user?.email ?? '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final primaryColor = const Color(0xFFF45B69);
    final baseFontSize = accessibilityProvider.fontSize;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: Text(
          'Welcome, $userDisplayName',
          style: accessibilityProvider.getTextStyle(sizeMultiplier: 1.25),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccessibilitySettingsPage(),
                ),
              );
            },
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
              // User Profile Header
              Card(
                elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildProfileAvatar(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userDisplayName,
                              style: accessibilityProvider.getTextStyle(
                                sizeMultiplier: 1.25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: accessibilityProvider.getTextStyle(
                                sizeMultiplier: 0.87,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfilePage(),
                            ),
                          ).then((_) {
                            if (!_isDisposed) {
                              _loadUserProfile();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: accessibilityProvider.getTextStyle(
                  sizeMultiplier: 1.25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: [
                  _buildQuickActionCard(
                    'Translate Sign Language',
                    Icons.sign_language,
                    Colors.blue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignTranslatePage())),
                  ),
                  _buildQuickActionCard(
                    'Patient-Doctor\nConversation',
                    Icons.chat,
                    Colors.green,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationModePage())),
                  ),
                  _buildQuickActionCard(
                    'AI Health\nCheck-In',
                    Icons.favorite,
                    Colors.red,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthCheckinPage())),
                  ),
                  _buildQuickActionCard(
                    'Telemedicine',
                    Icons.video_call,
                    Colors.orange,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelemedicinePage())),
                  ),
                  _buildQuickActionCard(
                    'Learn &\nPractice',
                    Icons.school,
                    Colors.purple,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningGamifiedPage())),
                  ),
                  _buildQuickActionCard(
                    'Hospital\nServices',
                    Icons.local_hospital,
                    primaryColor,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalGuidePage())),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Progress Tracking
              _buildChartCard('Progress Tracking', _buildProgressChart()),
              
              const SizedBox(height: 16),
              
              // Recent Interactions
              _buildChartCard('Recent Interactions', _buildRecentInteractions()),
              
              const SizedBox(height: 16),
              
              // Medication Overview
              _buildChartCard('Medication Overview', _buildMedicationOverview()),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final baseFontSize = accessibilityProvider.fontSize;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: accessibilityProvider.highContrast ? 2 : 1,
          ),
        ),
        padding: EdgeInsets.all(baseFontSize * 0.75),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(baseFontSize * 0.5),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon, 
                color: Colors.white, 
                size: baseFontSize * 1.5,
              ),
            ),
            SizedBox(height: baseFontSize * 0.5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: accessibilityProvider.getTextStyle(
                sizeMultiplier: 0.75,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final primaryColor = const Color(0xFFF45B69);

    return Card(
      elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: accessibilityProvider.getTextStyle(
                sizeMultiplier: 1.0,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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

  Widget _buildProgressBar(String label, int percentage, Color color) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 60,
          width: 20,
          child: RotatedBox(
            quarterTurns: 3,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$percentage%',
          style: accessibilityProvider.getTextStyle(
            fontWeight: FontWeight.bold, 
            sizeMultiplier: 0.75,
          ),
        ),
        Text(
          label,
          style: accessibilityProvider.getTextStyle(sizeMultiplier: 0.625),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRecentInteractions() {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    
    final interactions = [
      {'time': '10:30 AM', 'type': 'Translation Session', 'status': 'Completed'},
      {'time': '2:15 PM', 'type': 'Doctor Consultation', 'status': 'Upcoming'},
      {'time': 'Yesterday', 'type': 'Sign Practice', 'status': 'Completed'},
    ];

    return Column(
      children: interactions.map((item) {
        Color statusColor = item['status'] == 'Completed' 
            ? Colors.green 
            : item['status'] == 'Upcoming' 
                ? Colors.orange 
                : Colors.grey;
                
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.history, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item['type']!,
                      style: accessibilityProvider.getTextStyle(
                        sizeMultiplier: 0.87,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['time']!,
                      style: accessibilityProvider.getTextStyle(
                        sizeMultiplier: 0.75,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 60),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['status']!,
                  style: accessibilityProvider.getTextStyle(
                    sizeMultiplier: 0.68,
                    color: statusColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMedicationOverview() {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    
    final medications = [
      {'name': 'Medication A', 'time': '8:00 AM', 'status': 'Taken'},
      {'name': 'Medication B', 'time': '2:00 PM', 'status': 'Pending'},
      {'name': 'Medication C', 'time': '8:00 PM', 'status': 'Upcoming'},
    ];

    return Column(
      children: medications.map((med) {
        Color statusColor = med['status'] == 'Taken' 
            ? Colors.green 
            : med['status'] == 'Pending' 
                ? Colors.orange 
                : Colors.grey;
                
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.medication, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      med['name']!,
                      style: accessibilityProvider.getTextStyle(
                        sizeMultiplier: 0.87,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Time: ${med['time']}',
                      style: accessibilityProvider.getTextStyle(
                        sizeMultiplier: 0.75,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 60),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  med['status']!,
                  style: accessibilityProvider.getTextStyle(
                    sizeMultiplier: 0.68,
                    color: statusColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfileAvatar() {
    final primaryColor = const Color(0xFFF45B69);
    
    if (userProfileUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 35,
        backgroundColor: Colors.grey.shade300,
        child: ClipOval(
          child: Image.network(
            userProfileUrl,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.person, size: 35, color: primaryColor);
            },
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: 35,
        backgroundColor: primaryColor.withOpacity(0.1),
        child: Icon(Icons.person, size: 35, color: primaryColor),
      );
    }
  }

  Widget _buildDrawer() {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
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
                _buildProfileAvatar(),
                const SizedBox(height: 8),
                Text(
                  userDisplayName,
                  style: accessibilityProvider.getTextStyle(
                    sizeMultiplier: 1.12,
                    color: Colors.white,
                  ),
                ),
                Text(
                  userEmail,
                  style: accessibilityProvider.getTextStyle(
                    sizeMultiplier: 0.87,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.translate,
            title: 'Translate Sign Language',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SignTranslatePage()));
            },
          ),
          _buildDrawerItem(
            icon: Icons.chat,
            title: 'Patient-Doctor Conversation',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationModePage()));
            },
          ),
          _buildDrawerItem(
            icon: Icons.history,
            title: 'Medical History',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalRecordsPage()));
            },
          ),
          _buildDrawerItem(
            icon: Icons.favorite,
            title: 'AI Health Check-In',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthCheckinPage()));
            },
          ),
          _buildDrawerItem(
            icon: Icons.video_call,
            title: 'Telemedicine',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TelemedicinePage()));
            },
          ),
          _buildDrawerItem(
            icon: Icons.school,
            title: 'Learn & Practice',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningGamifiedPage()));
            },
          ),
          _buildDrawerItem(
            icon: Icons.local_hospital,
            title: 'Hospital Services',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalGuidePage()));
            },
          ),
          _buildDrawerItem(
            icon: Icons.help,
            title: 'Tutorial & Support',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialSupportPage()));
            },
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Family Portal',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyPortalPage()));
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Accessibility Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilitySettingsPage()));
            },
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);

    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: accessibilityProvider.getTextStyle(),
      ),
      onTap: onTap,
    );
  }
  
  Future<void> _handleLogout() async {
    // Close the drawer first
    Navigator.pop(context);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF45B69),
        ),
      ),
    );
    
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Navigate to login page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}