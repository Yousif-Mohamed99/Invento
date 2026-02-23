import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:invento/core/injection_container.dart';
import 'package:invento/features/home/presentation/pages/orders_list_screen.dart';
import 'package:invento/features/home/presentation/pages/profile_screen.dart';
import 'package:invento/features/home/presentation/pages/subscription_paywall.dart';
import 'package:invento/features/products/presentation/bloc/products_bloc.dart';
import 'package:invento/features/products/presentation/pages/add_product_screen.dart';
import 'package:invento/features/products/presentation/pages/products_screen.dart';
import 'dashboard_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  bool _isTrialExpired = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  final List<Widget> _pages = [
    const DashboardScreen(),
    const ProductsScreen(),
    const OrdersListScreen(),
    const ProfileScreen(),
  ];

  Future<void> _checkSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email == dotenv.env['ADMIN_EMAIL']) {
      setState(() {
        _isTrialExpired = false; // الأدمن دائماً حسابه مفتوح
      });
      return; // اخرج من الدالة ولا تكمل الفحص
    }
    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('merchants')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final bool isSubscribed = data['isSubscribed'] ?? false;
        final Timestamp? trialEndsAt = data['trialEndsAt'] as Timestamp?;
        final Timestamp? subscriptionEndDate =
            data['subscriptionEndDate'] as Timestamp?;

        bool isExpired = false;

        if (isSubscribed && subscriptionEndDate != null) {
          if (Timestamp.now().seconds > subscriptionEndDate.seconds) {
            isExpired = true;
          }
        } else if (trialEndsAt != null) {
          if (Timestamp.now().seconds > trialEndsAt.seconds) {
            isExpired = true;
          }
        }

        setState(() {
          _isTrialExpired = isExpired;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isTrialExpired) {
      return SubscriptionPaywall(
        email: FirebaseAuth.instance.currentUser?.email ?? "مستخدم غير معروف",
        isTrialExpired: true,
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFF2563EB),
              unselectedItemColor: Colors.blueGrey.shade300,
              selectedFontSize: 13,
              unselectedFontSize: 12,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.dashboard_rounded, size: 26),
                  ),
                  label: "الرئيسية",
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.inventory_2_rounded, size: 26),
                  ),
                  label: "المنتجات",
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.shopping_bag_rounded, size: 26),
                  ),
                  label: "الطلبات",
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.person_rounded, size: 26),
                  ),
                  label: "حسابي",
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton(
                // يظهر فقط في الرئيسية
                onPressed: () => _navigateToAddProduct(context),
                backgroundColor: const Color(0xFF2563EB),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              )
              : null,
    );
  }

  void _navigateToAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BlocProvider<ProductsBloc>(
              create: (context) => sl<ProductsBloc>(),
              child: const AddProductScreen(),
            ),
      ),
    );
  }
}
