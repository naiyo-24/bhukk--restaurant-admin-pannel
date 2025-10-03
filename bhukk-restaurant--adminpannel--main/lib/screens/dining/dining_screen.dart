// screens/dining/dining_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/main_scaffold.dart';
import 'dashboard_overview.dart';
import 'table_grid_view.dart';
import 'reservation_table_view.dart';
import 'dining_order_view.dart';
import 'dining_payment_view.dart';
import 'dining_feedback_view.dart';
import 'dining_analytics_view.dart';

class DiningScreen extends StatelessWidget {
  const DiningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Dining',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DiningDashboardOverview(),
                TableGridView(),
                ReservationTableView(),
                DiningOrderView(),
                DiningPaymentView(),
                DiningFeedbackView(),
                DiningAnalyticsView(),
              ],
            ),
          );
        },
      ),
    );
  }
}
