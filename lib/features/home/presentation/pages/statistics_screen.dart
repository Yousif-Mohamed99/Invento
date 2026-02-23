import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invento/core/models/subscription_plan.dart';
import 'package:invento/features/orders/domain/entities/order_entity.dart';
import 'package:invento/features/orders/domain/usecases/calculate_profit_usecase.dart';
import 'package:invento/features/home/presentation/pages/subscription_paywall.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StatisticsScreen extends StatelessWidget {
  final List<OrderEntity> orders;

  const StatisticsScreen({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    final activeOrders =
        orders.where((o) => o.status != OrderStatus.cancelled).toList();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "إحصائيات الأداء",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('merchants')
                .doc(user?.uid)
                .snapshots(),
        builder: (context, snapshot) {
          String? planName;
          if (snapshot.hasData && snapshot.data!.exists) {
            planName = (snapshot.data!.data() as Map<String, dynamic>)['plan'];
          }
          final plan = SubscriptionPlan.fromString(planName);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("الملخص المالي"),
                const SizedBox(height: 15),
                _buildQuickStats(activeOrders),
                const SizedBox(height: 15),
                _buildSecondaryStats(activeOrders),

                const SizedBox(height: 30),
                _buildSectionTitle("مصادر الطلبات (Order Sources)"),
                const SizedBox(height: 15),
                _wrapWithLock(
                  context,
                  child: _buildSourcePieChart(activeOrders),
                  isLocked:
                      !plan.hasReports &&
                      user?.email != dotenv.env['ADMIN_EMAIL'],
                  userEmail: user?.email ?? "",
                ),

                const SizedBox(height: 30),
                _buildSectionTitle("تحليل المنتجات"),
                const SizedBox(height: 15),
                _wrapWithLock(
                  context,
                  child: Column(
                    children: [
                      _buildTopProductCard(activeOrders),
                      const SizedBox(height: 15),
                      _buildLeastProductCard(activeOrders),
                    ],
                  ),
                  isLocked:
                      !plan.hasReports &&
                      user?.email != dotenv.env['ADMIN_EMAIL'],
                  userEmail: user?.email ?? "",
                ),

                const SizedBox(height: 30),
                _buildSectionTitle("المحافظات الأكثر طلباً"),
                const SizedBox(height: 15),
                _wrapWithLock(
                  context,
                  child: _buildTopProvinces(activeOrders),
                  isLocked:
                      !plan.hasReports &&
                      user?.email != dotenv.env['ADMIN_EMAIL'],
                  userEmail: user?.email ?? "",
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _wrapWithLock(
    BuildContext context, {
    required Widget child,
    required bool isLocked,
    required String userEmail,
  }) {
    if (!isLocked) return child;

    return Stack(
      children: [
        Opacity(opacity: 0.05, child: AbsorbPointer(child: child)),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      color: Colors.blueGrey,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "هذه الميزة غير متوفرة في خطة البداية",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => SubscriptionPaywall(
                                  email: userEmail,
                                  isTrialExpired: false,
                                ),
                          ),
                        );
                      },
                      child: const Text(
                        "ترقية الخطة الآن",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopProvinces(List<OrderEntity> orders) {
    if (orders.isEmpty) return const SizedBox();

    Map<String, int> cityStats = {};
    for (var order in orders) {
      if (order.city.isNotEmpty) {
        cityStats[order.city] = (cityStats[order.city] ?? 0) + 1;
      }
    }

    if (cityStats.isEmpty) {
      return const Center(child: Text("لا توجد بيانات للمناطق حالياً"));
    }

    var sortedCities =
        cityStats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children:
            sortedCities.take(5).map((entry) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.blueAccent,
                    size: 18,
                  ),
                ),
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("محافظة / مدينة"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${entry.value} طلب",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A8A),
        ),
      ),
    );
  }

  Widget _buildQuickStats(List<OrderEntity> orders) {
    final profitCalculator = CalculateProfitUseCase();
    double totalNetProfit = profitCalculator.executeTotal(orders);
    double totalRevenue = orders.fold(0, (sum, item) => sum + item.totalAmount);

    return Row(
      children: [
        _statCard(
          "صافي الربح",
          "${totalNetProfit.toStringAsFixed(0)} ج.م",
          Colors.green,
          Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(width: 12),
        _statCard(
          "إجمالي المبيعات",
          "${totalRevenue.toStringAsFixed(0)} ج.م",
          Colors.orange,
          Icons.payments_outlined,
        ),
      ],
    );
  }

  Widget _buildSecondaryStats(List<OrderEntity> orders) {
    int totalOrders = orders.length;
    int totalProductsSold = orders.fold(0, (sum, order) {
      return sum + order.items.fold(0, (s, item) => s + item.quantity);
    });

    return Row(
      children: [
        _statCard(
          "إجمالي الطلبات",
          totalOrders.toString(),
          Colors.blueAccent,
          Icons.shopping_bag_outlined,
        ),
        const SizedBox(width: 12),
        _statCard(
          "المنتجات المباعة",
          totalProductsSold.toString(),
          Colors.purple,
          Icons.inventory_2_outlined,
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourcePieChart(List<OrderEntity> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text("لا توجد بيانات حالياً"));
    }

    Map<OrderSource, int> counts = {};
    for (var o in orders) {
      counts[o.source] = (counts[o.source] ?? 0) + 1;
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections:
              counts.entries.map((e) {
                return PieChartSectionData(
                  value: e.value.toDouble(),
                  title:
                      '${((e.value / orders.length) * 100).toStringAsFixed(0)}%',
                  color: _getSourceColor(e.key),
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  badgeWidget: Text(
                    e.key.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  badgePositionPercentageOffset: 1.3,
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopProductCard(List<OrderEntity> orders) {
    if (orders.isEmpty) return const SizedBox();

    Map<String, int> productSales = {};
    for (var order in orders) {
      for (var item in order.items) {
        productSales[item.productName] =
            (productSales[item.productName] ?? 0) + item.quantity;
      }
    }

    if (productSales.isEmpty) return const SizedBox();

    var sortedProducts =
        productSales.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    String bestSeller = sortedProducts.first.key;
    int salesCount = sortedProducts.first.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.yellow,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "الأكثر مبيعاً",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  bestSeller,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "تم بيع $salesCount قطعة",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeastProductCard(List<OrderEntity> orders) {
    if (orders.isEmpty) return const SizedBox();

    Map<String, int> productSales = {};
    for (var order in orders) {
      for (var item in order.items) {
        productSales[item.productName] =
            (productSales[item.productName] ?? 0) + item.quantity;
      }
    }

    if (productSales.isEmpty) return const SizedBox();

    var sortedProducts =
        productSales.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    String leastSeller = sortedProducts.first.key;
    int salesCount = sortedProducts.first.value;

    // If there's only one product, don't show "Least Selling" as it's the same as "Top"
    if (productSales.length <= 1) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[800]!, Colors.grey[600]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_down_rounded,
              color: Colors.orangeAccent,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "الأقل مبيعاً",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  leastSeller,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "تم بيع $salesCount قطعة",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSourceColor(OrderSource source) {
    switch (source) {
      case OrderSource.facebook:
        return Colors.blue[800]!;
      case OrderSource.whatsapp:
        return Colors.green[600]!;
      case OrderSource.instagram:
        return Colors.pink[400]!;
      case OrderSource.tiktok:
        return Colors.black;
      default:
        return Colors.grey;
    }
  }
}
