import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:invento/features/auth/presentation/pages/login_screen.dart';
import 'package:invento/features/home/presentation/pages/help_center_screen.dart';
import 'package:invento/features/home/presentation/pages/order_details_screen.dart';
import 'package:invento/features/home/presentation/pages/social_order_creator.dart';
import 'package:invento/features/home/presentation/pages/statistics_screen.dart';
import 'package:invento/features/home/presentation/pages/subscription_paywall.dart';
import 'package:invento/features/orders/domain/entities/order_entity.dart';
import 'package:invento/features/orders/domain/repositories/orders_repository.dart';
import 'package:invento/features/orders/domain/repositories/products_repository.dart';
import 'package:invento/features/products/data/models/activity_model.dart';
import 'package:invento/features/products/data/models/product_model.dart';
import 'package:invento/features/products/presentation/bloc/orders_bloc.dart';
import 'package:invento/features/products/presentation/bloc/orders_event.dart';
import 'package:invento/features/products/presentation/bloc/orders_state.dart';
import 'package:invento/features/products/presentation/bloc/products_bloc.dart';
import 'package:invento/features/products/presentation/bloc/products_state.dart';
import 'package:invento/features/products/presentation/pages/product_details_screen.dart';
import 'package:invento/features/products/presentation/pages/products_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

String _formatTime(DateTime dateTime) {
  return timeago.format(dateTime, locale: 'ar');
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<String> _dismissedActivityIds = [];

  @override
  void initState() {
    super.initState();
    _loadDismissedActivities();
    context.read<OrdersBloc>().add(LoadOrdersEvent());
  }

  Future<void> _loadDismissedActivities() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dismissedActivityIds = prefs.getStringList('dismissedActivities') ?? [];
    });
  }

  Future<void> _dismissActivity(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _dismissedActivityIds.add(id);
    await prefs.setStringList('dismissedActivities', _dismissedActivityIds);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "لوحة التحكم",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              } catch (e) {
                debugPrint("خطأ أثناء تسجيل الخروج: $e");
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumHeader(user),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: const TrialReminderBanner(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<OrdersBloc, OrdersState>(
                    builder: (context, state) {
                      final orders =
                          state is OrdersLoaded
                              ? state.orders
                              : <OrderEntity>[];
                      return _buildQuickActions(context, orders);
                    },
                  ),
                  const SizedBox(height: 25),
                  _buildSectionTitle("ملخص الأداء"),
                  const SizedBox(height: 15),
                  BlocBuilder<OrdersBloc, OrdersState>(
                    builder: (context, state) {
                      String todayCount = "0";
                      String todayEarnings = "0";

                      if (state is OrdersLoading) {
                        return const Center(child: LinearProgressIndicator());
                      } else if (state is OrdersLoaded) {
                        todayCount = state.todayOrdersCount.toString();
                        todayEarnings = state.todayEarnings.toStringAsFixed(0);
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: "طلبات اليوم",
                              value: todayCount,
                              icon: Icons.shopping_cart_checkout_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildStatCard(
                              title: "أرباح اليوم",
                              value: "$todayEarnings ج.م",
                              icon: Icons.account_balance_wallet_rounded,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  _buildSectionTitle("آخر الأنشطة"),
                  const SizedBox(height: 15),
                  StreamBuilder<List<ActivityModel>>(
                    stream: GetIt.I<OrdersRepository>().getActivitiesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child:
                            (!snapshot.hasData || snapshot.data!.isEmpty)
                                ? _buildEmptyActivitiesState()
                                : Builder(
                                  builder: (context) {
                                    final visibleActivities =
                                        snapshot.data!
                                            .where(
                                              (a) =>
                                                  !_dismissedActivityIds
                                                      .contains(a.id),
                                            )
                                            .toList();

                                    if (visibleActivities.isEmpty) {
                                      return _buildEmptyActivitiesState();
                                    }

                                    return ListView.builder(
                                      key: const ValueKey('list'),
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount:
                                          visibleActivities.length > 5
                                              ? 5
                                              : visibleActivities.length,
                                      itemBuilder: (context, index) {
                                        final activity =
                                            visibleActivities[index];

                                        return Dismissible(
                                          key: Key(activity.id),
                                          direction:
                                              DismissDirection.endToStart,
                                          confirmDismiss: (direction) async {
                                            return await showDialog(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                    title: const Text(
                                                      "تأكيد الحذف",
                                                    ),
                                                    content: const Text(
                                                      "هل أنت متأكد من مسح هذا النشاط من اللوحة؟",
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.of(
                                                              context,
                                                            ).pop(false),
                                                        child: const Text(
                                                          "إلغاء",
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                        ),
                                                        onPressed:
                                                            () => Navigator.of(
                                                              context,
                                                            ).pop(true),
                                                        child: const Text(
                                                          "نعم، امسح",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                          },
                                          onDismissed: (direction) {
                                            _dismissActivity(activity.id);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  "تم مسح النشاط من اللوحة",
                                                ),
                                                action: SnackBarAction(
                                                  label: "تراجع",
                                                  onPressed: () async {
                                                    final prefs =
                                                        await SharedPreferences.getInstance();
                                                    _dismissedActivityIds
                                                        .remove(activity.id);
                                                    await prefs.setStringList(
                                                      'dismissedActivities',
                                                      _dismissedActivityIds,
                                                    );
                                                    setState(() {});
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                          background: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            alignment: Alignment.centerLeft,
                                            padding: const EdgeInsets.only(
                                              left: 20,
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                            ),
                                          ),
                                          child: _buildActivityItem(
                                            title: activity.title,
                                            subtitle: activity.subtitle,
                                            time: _formatTime(
                                              activity.timestamp,
                                            ),
                                            icon:
                                                activity.type ==
                                                        ActivityType.newOrder
                                                    ? Icons.shopping_bag_rounded
                                                    : Icons
                                                        .warning_amber_rounded,
                                            color:
                                                activity.type ==
                                                        ActivityType.newOrder
                                                    ? const Color(0xFF2563EB)
                                                    : Colors.orange,
                                            onTap: () {
                                              if (activity.type ==
                                                  ActivityType.lowStock) {
                                                _navigateToProductDetails(
                                                  context,
                                                  activity.referenceId,
                                                );
                                              } else if (activity.type ==
                                                  ActivityType.newOrder) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (
                                                          context,
                                                        ) => OrderDetailsScreen(
                                                          orderId:
                                                              activity
                                                                  .referenceId,
                                                        ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(User? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 60, left: 25, right: 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "مرحباً بك،",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('merchants')
                            .doc(user?.uid)
                            .snapshots(),
                    builder: (context, snapshot) {
                      String storeName = user?.displayName ?? "تاجري العزيز";
                      if (snapshot.hasData && snapshot.data!.exists) {
                        storeName = snapshot.data!['storeName'] ?? storeName;
                      }
                      return Text(
                        storeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  child: Text(
                    user?.email?[0].toUpperCase() ?? "M",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                BlocBuilder<ProductsBloc, ProductsState>(
                  builder: (context, state) {
                    String count = "0";
                    if (state is ProductsLoaded) {
                      count = state.products.length.toString();
                    }
                    return _buildHeaderStat("المنتجات", count);
                  },
                ),
                BlocBuilder<OrdersBloc, OrdersState>(
                  builder: (context, state) {
                    String count = "0";
                    if (state is OrdersLoaded) {
                      count = state.orders.length.toString();
                    }
                    return _buildHeaderStat("إجمالي الطلبات", count);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, List<OrderEntity> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("إجراءات سريعة"),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(
              context,
              icon: Icons.add_business_rounded,
              label: "أوردر جديد",
              color: Colors.orange,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SmartOrderCreator()),
                  ),
            ),
            _buildActionItem(
              context,
              icon: Icons.inventory_rounded,
              label: "المخزن",
              color: Colors.blueAccent,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductsScreen()),
                  ),
            ),
            _buildActionItem(
              context,
              icon: Icons.analytics_rounded,
              label: "التقارير",
              color: Colors.purple,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatisticsScreen(orders: orders),
                    ),
                  ),
            ),
            _buildActionItem(
              context,
              icon: Icons.support_agent_rounded,
              label: "الدعم",
              color: Colors.green,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E3A8A),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          Text(
                            time,
                            style: TextStyle(
                              color: Colors.blueGrey.shade300,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyActivitiesState() {
    return const Padding(
      key: ValueKey('empty'),
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.done_all_rounded, color: Colors.green, size: 50),
            SizedBox(height: 16),
            Text(
              "كل الأنشطة مكتملة حالياً",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _navigateToProductDetails(
  BuildContext context,
  String productId,
) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (context) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
  );

  try {
    final product = await GetIt.I<ProductsRepository>().getProductById(
      productId,
    );

    if (context.mounted) Navigator.pop(context);

    if (context.mounted && product != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => BlocProvider.value(
                value: context.read<ProductsBloc>(),
                child: ProductDetailsScreen(product: product as ProductModel),
              ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ: ${e.toString()}")));
    }
  }
}

class TrialReminderBanner extends StatelessWidget {
  const TrialReminderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.email == dotenv.env['ADMIN_EMAIL']) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('merchants')
              .doc(user?.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final bool isSubscribed = data['isSubscribed'] ?? false;
        final Timestamp? trialEndsAt = data['trialEndsAt'] as Timestamp?;
        final Timestamp? subscriptionEndDate =
            data['subscriptionEndDate'] as Timestamp?;

        final now = DateTime.now();

        if (isSubscribed) {
          if (subscriptionEndDate != null) {
            final remainingDays =
                subscriptionEndDate.toDate().difference(now).inDays;
            if (remainingDays <= 7 && remainingDays >= 0) {
              return _buildBanner(
                context,
                title: "تجديد الاشتراك",
                message: "ينتهي اشتراكك الحالي خلال $remainingDays أيام.",
                color: Colors.redAccent,
                email: user?.email,
              );
            }
          }
          return const SizedBox.shrink();
        }

        if (trialEndsAt != null) {
          final remainingDays = trialEndsAt.toDate().difference(now).inDays;
          if (remainingDays >= 0) {
            return _buildBanner(
              context,
              title: "تنبيه انتهاء التجربة",
              message:
                  "باقي $remainingDays أيام فقط على انتهاء الفترة التجريبية.",
              color: Colors.orange.shade700,
              email: user?.email,
            );
          }
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBanner(
    BuildContext context, {
    required String title,
    required String message,
    required Color color,
    String? email,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [color, color.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => SubscriptionPaywall(
                                email: email ?? "",
                                isTrialExpired: false,
                              ),
                        ),
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "اشترك الآن",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
