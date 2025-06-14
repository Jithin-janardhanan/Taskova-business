// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:taskova_shopkeeper/view/instant_job_post.dart';
// import 'package:taskova_shopkeeper/view/schedulejob_post.dart';
// import 'package:taskova_shopkeeper/view/mypost.dart';
// // Import your BusinessJobPostsPage
// // Adjust the import path as needed

// class Dashboard extends StatefulWidget {
//   const Dashboard({super.key});

//   @override
//   State<Dashboard> createState() => _DashboardState();
// }

// class _DashboardState extends State<Dashboard> {
//   Future<bool> _onExit(BuildContext context) async {
//     bool shouldExit = await showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: Text('Exit Dashboard?'),
//             content: Text('Are you sure you want to leave this page?'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(true),
//                 child: Text('Exit'),
//               ),
//             ],
//           ),
//     );
//     return shouldExit;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvoked: (didPop) async {
//         if (didPop) return;

//         bool exit = await _onExit(context);
//         if (exit) {
//           if (Navigator.of(context).canPop()) {
//             Navigator.of(context).pop();
//           } else {
//             SystemNavigator.pop(); // Or use exit(0) from dart:io
//           }
//         }
//       },
//       child: Scaffold(
//         appBar: AppBar(title: Text("Takeaway Owner Dashboard"), actions: [

//           ],
//         ),
//         body: SingleChildScrollView(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 1. Welcome / Overview
//               Text(
//                 "Welcome back!",
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 8),
//               Text(
//                 "Post a job to hire a delivery driver today or for a specific date.",
//               ),

//               SizedBox(height: 24),

//               // 2. Post a Job Section
//               Text(
//                 "Create a Job Post",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               SizedBox(height: 12),

//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       icon: Icon(Icons.flash_on),
//                       label: Text("Hire for Today"),
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const InstatJobPost(),
//                           ),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         padding: EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 16),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       icon: Icon(Icons.calendar_today),
//                       label: Text("Hire for Another Day"),
//                       onPressed: () {
//                         // Show 'specific date job' form
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const ScheduleJobPost(),
//                           ),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                         padding: EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               SizedBox(height: 32),

//               // 3. Active Job Posts List
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Active Job Posts",
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                   ),
//                   TextButton.icon(
//                     icon: Icon(Icons.arrow_forward),
//                     label: Text("View All"),
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => MyJobpost()),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//               SizedBox(height: 12),

//               // Embedded job posts list
//               Container(
//                 height: 400, // Adjust height as needed
//                 // child: BusinessJobPostsPage(show AppBar: false),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskova_shopkeeper/Model/colors.dart';
import 'package:taskova_shopkeeper/view/Jobpost/expired_jobs.dart';
import 'package:taskova_shopkeeper/view/Jobpost/instant_job_post.dart';
import 'package:taskova_shopkeeper/view/Jobpost/job_manage.dart';
import 'package:taskova_shopkeeper/view/Jobpost/schedulejob_post.dart';
import 'package:taskova_shopkeeper/view/Jobpost/mypost.dart';
import 'package:taskova_shopkeeper/view/verification.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Future<bool> _onExit(BuildContext context) async {
    bool shouldExit = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.exit_to_app, color: Colors.orange),
                SizedBox(width: 8),
                Text('Exit Dashboard?'),
              ],
            ),
            content: Text('Are you sure you want to leave this page?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Exit'),
              ),
            ],
          ),
    );
    return shouldExit;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        bool exit = await _onExit(context);
        if (exit) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.primaryBlue,
          title: Center(
            child: Text(
              "Taskova",
              style: TextStyle(
                color: const Color.fromARGB(255, 245, 244, 244),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            // Add refresh logic here
            await Future.delayed(Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                _buildWelcomeHeader(),
                SizedBox(height: 24),

                // Stats Cards
                _buildStatsCards(),
                SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(context),
                SizedBox(height: 24),

                // Recent Activity Section
                _buildRecentActivity(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Manage your delivery jobs and grow your business",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.restaurant_menu, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard("Active Jobs", "12", Icons.work, Colors.green),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "Applications",
            "28",
            Icons.people,
            Colors.blue,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "This Month",
            "45",
            Icons.trending_up,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                "Hire for Today",
                "Post an instant job",
                Icons.flash_on,
                Colors.green,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InstatJobPost()),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                "Schedule Job",
                "Plan for later",
                Icons.schedule,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScheduleJobPost(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                "My Job Posts",
                "View all posts",
                Icons.list_alt,
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobManagementPage(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                "Analytics",
                "View reports",
                Icons.analytics,
                Colors.purple,
                () {
                  // Navigate to analytics
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Analytics coming soon!")),
                  );
                  //                   Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => ExpiredJobsPage()),
                  // );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Activity",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            TextButton.icon(
              icon: Icon(Icons.arrow_forward, size: 16),
              label: Text("View All"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JobManagementPage()),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String time,
  ) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
