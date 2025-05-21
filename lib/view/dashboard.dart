import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskova_shopkeeper/view/business_detial_filling.dart';
import 'package:taskova_shopkeeper/view/instant_job_post.dart';
import 'package:taskova_shopkeeper/view/job_post.dart';
import 'package:taskova_shopkeeper/view/mypost.dart';
// Import your BusinessJobPostsPage
// Adjust the import path as needed

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
            title: Text('Exit Dashboard?'),
            content: Text('Are you sure you want to leave this page?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
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
            SystemNavigator.pop(); // Or use exit(0) from dart:io
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text("Takeaway Owner Dashboard"), actions: [
            
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Welcome / Overview
              Text(
                "Welcome back!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Post a job to hire a delivery driver today or for a specific date.",
              ),

              SizedBox(height: 24),

              // 2. Post a Job Section
              Text(
                "Create a Job Post",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.flash_on),
                      label: Text("Hire for Today"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InstatJobPost(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.calendar_today),
                      label: Text("Hire for Another Day"),
                      onPressed: () {
                        // Show 'specific date job' form
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScheduleJobPost(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32),

              // 3. Active Job Posts List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Active Job Posts",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.arrow_forward),
                    label: Text("View All"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyJobpost()),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Embedded job posts list
              Container(
                height: 400, // Adjust height as needed
                // child: BusinessJobPostsPage(show AppBar: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
