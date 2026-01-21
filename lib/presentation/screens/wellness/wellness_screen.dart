import 'package:flutter/material.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/presentation/screens/wellness/budget_tracker_screen.dart';
import 'package:personal_haven/presentation/screens/wellness/food_diary_screen.dart';
import 'package:personal_haven/presentation/screens/wellness/goals_screen.dart';

/// Wellness Screen - Tab view for Food Diary, Budget, and Goals
class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 40,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Wellness',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryLight,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: [
                    Tab(
                      icon: Icon(
                        Icons.restaurant,
                        color: _currentIndex == 0 ? Colors.white : Colors.white70,
                      ),
                      text: 'Food',
                    ),
                    Tab(
                      icon: Icon(
                        Icons.account_balance_wallet,
                        color: _currentIndex == 1 ? Colors.white : Colors.white70,
                      ),
                      text: 'Budget',
                    ),
                    Tab(
                      icon: Icon(
                        Icons.flag,
                        color: _currentIndex == 2 ? Colors.white : Colors.white70,
                      ),
                      text: 'Goals',
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: const [
            FoodDiaryScreen(),
            BudgetScreen(),
            GoalsScreen(),
          ],
        ),
      ),
    );
  }
}

/// Sliver Tab Bar Delegate for pinned tabs
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.primary,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}