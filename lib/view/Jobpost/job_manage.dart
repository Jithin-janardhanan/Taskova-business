import 'package:flutter/material.dart';
import 'package:taskova_shopkeeper/Model/colors.dart';
import 'package:taskova_shopkeeper/view/Jobpost/expired_jobs.dart';
import 'package:taskova_shopkeeper/view/Jobpost/mypost.dart';
import 'package:taskova_shopkeeper/view/bottom_nav.dart';

class JobManagementPage extends StatefulWidget {
  final int initialTabIndex;

  const JobManagementPage({Key? key, this.initialTabIndex = 0})
    : super(key: key);

  @override
  State<JobManagementPage> createState() => _JobManagementPageState();
}

class _JobManagementPageState extends State<JobManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomePageWithBottomNav()),
          (Route<dynamic> route) => false, // removes all previous routes
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => HomePageWithBottomNav(),
                      ),
                      (Route<dynamic> route) =>
                          false, // removes all previous routes
                    );
                  },
                ),
              ),
              title: const Text(
                'Job Management',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,

              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),

                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkText.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),

                    indicatorPadding: const EdgeInsets.symmetric(
                      vertical: 1,
                      horizontal: -15,
                    ),
                    labelColor: AppColors.primaryBlue,
                    unselectedLabelColor: Colors.white,

                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.work_outline, size: 16),
                            const SizedBox(width: 6),
                            Text('Active'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 16),
                            const SizedBox(width: 6),
                            Text('Expired'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Container(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(const MyJobpostTabContent()),
              _buildTabContent(const ExpiredJobsTabContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(Widget child) {
    return Container(padding: const EdgeInsets.only(top: 8), child: child);
  }
}

// Wrapper for MyJobpost without AppBar
class MyJobpostTabContent extends StatelessWidget {
  const MyJobpostTabContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const MyJobpostContent(),
    );
  }
}

// Wrapper for ExpiredJobsPage without AppBar
class ExpiredJobsTabContent extends StatelessWidget {
  const ExpiredJobsTabContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const ExpiredJobsContent(),
    );
  }
}
