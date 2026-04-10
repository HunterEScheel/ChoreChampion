import 'package:flutter/material.dart';

import '../widgets/submissions_tab.dart';
import '../widgets/chores_tab.dart';
import '../widgets/members_tab.dart';
import '../widgets/rewards_config_tab.dart';
import '../widgets/devices_tab.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Submissions'),
              Tab(text: 'Chores'),
              Tab(text: 'Members'),
              Tab(text: 'Rewards'),
              Tab(text: 'Devices'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                SubmissionsTab(),
                ChoresTab(),
                MembersTab(),
                RewardsConfigTab(),
                DevicesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
