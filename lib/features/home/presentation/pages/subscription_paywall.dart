import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:invento/core/models/subscription_plan.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionPaywall extends StatefulWidget {
  final String email;
  final bool isTrialExpired;
  const SubscriptionPaywall({
    super.key,
    required this.email,
    this.isTrialExpired = true,
  });

  @override
  State<SubscriptionPaywall> createState() => _SubscriptionPaywallState();
}

class _SubscriptionPaywallState extends State<SubscriptionPaywall> {
  PlanType selectedPlan = PlanType.growth;

  Future<void> _launchWhatsApp(SubscriptionPlan plan) async {
    var phoneNumber = dotenv.env['SUPPORT_PHONE'];
    String message =
        "أريد تفعيل اشتراك باقة (${plan.name}) لتطبيق Invento لحسابي: ${widget.email}";

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': user?.uid,
        'userEmail': widget.email,
        'message': "طلب تفعيل باقة: ${plan.name} (عبر واتساب)",
        'createdAt': Timestamp.now(),
        'status': 'open',
      });
    } catch (e) {
      debugPrint("خطأ في تسجيل الطلب: $e");
    }

    String url =
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading:
            !widget.isTrialExpired
                ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                )
                : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            const Icon(Icons.stars_rounded, size: 60, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              "اختر خطة نجاحك",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "اختر الباقة المناسبة لحجم تجارتك وابدأ النمو اليوم",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ...SubscriptionPlan.plans.map((plan) => _buildPlanCard(plan)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed:
                  () => _launchWhatsApp(
                    SubscriptionPlan.plans.firstWhere(
                      (p) => p.type == selectedPlan,
                    ),
                  ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.whatsapp, size: 20),
                  SizedBox(width: 12),
                  Text(
                    "تفعيل باقتي الآن",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: Text(
                "تسجيل الخروج",
                style: TextStyle(color: Colors.red[400], fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    bool isSelected = selectedPlan == plan.type;
    Color primaryColor =
        plan.type == PlanType.pro
            ? const Color(0xFF1E3A8A)
            : plan.type == PlanType.growth
            ? Colors.blueAccent
            : Colors.grey[700]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey[200]!,
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: InkWell(
        onTap: () => setState(() => selectedPlan = plan.type),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? primaryColor : Colors.black87,
                        ),
                      ),
                      Text(
                        plan.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    plan.price,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Divider(),
              ),
              _buildFeature(
                "حتى ${plan.productLimit == -1 ? 'لا محدود' : plan.productLimit} منتج",
                true,
              ),
              _buildFeature(
                "${plan.orderLimit == -1 ? 'طلبات غير محدودة' : 'حتى ${plan.orderLimit} طلب شهرياً'}",
                true,
              ),
              _buildFeature("تقارير أداء متقدمة", plan.hasReports),
              _buildFeature("دعم فني خاص", plan.hasSpecialSupport),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(String text, bool available) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: available ? Colors.green[400] : Colors.grey[300],
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: available ? Colors.black87 : Colors.grey[400],
              decoration: available ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}
