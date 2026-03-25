import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Privacy Policy",
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Icon(
                Icons.privacy_tip_outlined,
                size: 60,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 24),

            _buildCard(
              title: "Introduction",
              content:
                  "Welcome to Invento.\n\n"
                  "We are committed to protecting your data privacy and providing a secure environment for managing your business. This policy explains how we collect and use your data transparently.",
            ),

            _buildCard(
              title: "1. Data We Collect",
              content:
                  "• Identity Data: (Name, email, and store name).\n"
                  "• Business Data: (Products, stock, and orders) to facilitate management.\n"
                  "• Contact Data: Phone number in case of contact with technical support.",
            ),

            _buildCard(
              title: "2. How We Use Your Data?",
              content:
                  "We use the data to manage your account, provide app features, and communicate with you regarding your monthly subscription or to provide technical support.",
            ),

            _buildCard(
              title: "3. Payment Methods & Subscription Activation",
              content:
                  "Subscription is currently activated through direct communication with technical support via (WhatsApp).\n\n"
                  "Once the transfer is confirmed, your account is activated manually. We do not ask for any confidential data "
                  "such as visa numbers or bank passwords within the app.",
            ),

            _buildCard(
              title: "4. Data Security",
              content:
                  "All data is stored securely and encrypted via Google Firebase servers, and we ensure security systems are updated regularly to ensure maximum protection.",
            ),

            _buildCard(
              title: "5. Trial Period & Subscription",
              content:
                  "Invento grants every new user a 7-day trial period. "
                  "After this period ends, the app stops automatically, and you must contact management via WhatsApp "
                  "to renew the monthly subscription to continue accessing your stock data.",
            ),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "I understand, Back",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.blueGrey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
