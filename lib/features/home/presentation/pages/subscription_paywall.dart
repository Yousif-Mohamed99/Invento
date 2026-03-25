import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:invento/core/models/subscription_plan.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  /// Open WhatsApp support for subscription
  Future<void> _launchWhatsApp(SubscriptionPlan plan) async {
    var phoneNumber = dotenv.env['SUPPORT_PHONE'];
    String message = AppLocalizations.of(context)!.plan_activation_whatsapp_msg(plan.name, widget.email);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': user?.uid,
        'userEmail': widget.email,
        'message': "Plan activation request: ${plan.name} (via WhatsApp)",
        'createdAt': Timestamp.now(),
        'status': 'open',
      });
    } catch (e) {
      debugPrint("Error recording request: $e");
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
            Text(
              AppLocalizations.of(context)!.choose_success_plan,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.choose_plan_desc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ...SubscriptionPlan.plans.map((plan) => _buildPlanCard(plan)),
            const SizedBox(height: 24),
            // WhatsApp Support Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FontAwesomeIcons.whatsapp, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.choose_plan_whatsapp,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: Text(
                AppLocalizations.of(context)!.sign_out,
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
                context,
                plan.productLimit == -1
                    ? AppLocalizations.of(context)!.unlimited_products
                    : AppLocalizations.of(context)!.up_to_products(plan.productLimit),
                true,
              ),
              _buildFeature(
                context,
                plan.orderLimit == -1
                    ? AppLocalizations.of(context)!.unlimited_orders
                    : AppLocalizations.of(context)!.up_to_orders_month(plan.orderLimit),
                true,
              ),
              _buildFeature(context, AppLocalizations.of(context)!.advanced_reports, plan.hasReports),
              _buildFeature(context, AppLocalizations.of(context)!.special_technical_support, plan.hasSpecialSupport),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(BuildContext context, String text, bool available) {
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
