// // EXAMPLE: Thay thế Transaction bằng AI trong bottom navigation

// // Trong HomeView.dart (hoặc bất kỳ view nào có bottom nav):

// // 1. ADD IMPORT:
// import './Build_AI/AI_insight_view.dart';

// // 2. REPLACE NAVIGATION ITEM:
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import './HomeView.dart';
// import './AnalysisView.dart';
// import './CategorizeContent.dart';
// import './ProfileView.dart';
// import './AddExpenseView.dart';
// import '../notification/NotificationView.dart';
// import './transaction_widgets.dart';

// // BEFORE (Transaction):
// _buildNavItem(
//   Icons.swap_horiz,    // ← Transaction icon
//   false,
//   Colors.grey[400]!,
//   onTap: () {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const TransactionView(),  // ← Old
//       ),
//     );
//   },
// ),

// // AFTER (AI):
// _buildNavItem(
//   Icons.psychology,    // ← AI icon
//   false,
//   Colors.grey[400]!,
//   onTap: () {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const AIInsightsView(),  // ← New
//       ),
//     );
//   },
// ),

// // 3. FULL BOTTOM NAV EXAMPLE:
// Widget _buildBottomNavBar(bool isDark) {
//   return Container(
//     decoration: BoxDecoration(
//       color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
//       boxShadow: [
//         BoxShadow(
//           color: Colors.grey.withOpacity(0.1),
//           blurRadius: 10,
//           offset: const Offset(0, -5),
//         ),
//       ],
//     ),
//     child: SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             // Home
//             _buildNavItem(
//               Icons.home,
//               true,  // Active if on HomeView
//               const Color(0xFF00CED1),
//               onTap: () {},
//             ),
            
//             // Analysis
//             _buildNavItem(
//               Icons.search,
//               false,
//               isDark ? Colors.grey[500]! : Colors.grey[400]!,
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const AnalysisView(),
//                   ),
//                 );
//               },
//             ),
            
//             // AI (REPLACED Transaction)
//             _buildNavItem(
//               Icons.psychology,  // ← AI icon
//               false,
//               isDark ? Colors.grey[500]! : Colors.grey[400]!,
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const AIInsightsView(),  // ← AI View
//                   ),
//                 );
//               },
//             ),
            
//             // Categories
//             _buildNavItem(
//               Icons.layers,
//               false,
//               isDark ? Colors.grey[500]! : Colors.grey[400]!,
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const CategoriesView(),
//                   ),
//                 );
//               },
//             ),
            
//             // Profile
//             _buildNavItem(
//               Icons.person_outline,
//               false,
//               isDark ? Colors.grey[500]! : Colors.grey[400]!,
//               onTap: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const ProfileView(),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }