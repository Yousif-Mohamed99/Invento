import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:invento/features/home/presentation/pages/admin_support_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:invento/core/models/subscription_plan.dart';
import 'package:invento/features/home/presentation/pages/subscription_paywall.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isSending = false;
  String _searchQuery = "";

  List<Map<String, String>> get _allFaqs {
    return [
      {
        "question": AppLocalizations.of(context)!.faq_q1,
        "answer": AppLocalizations.of(context)!.faq_a1,
      },
      {
        "question": AppLocalizations.of(context)!.faq_q2,
        "answer": AppLocalizations.of(context)!.faq_a2,
      },
      {
        "question": AppLocalizations.of(context)!.faq_q3,
        "answer": AppLocalizations.of(context)!.faq_a3,
      },
      {
        "question": AppLocalizations.of(context)!.faq_q4,
        "answer": AppLocalizations.of(context)!.faq_a4,
      },
    ];
  }

  List<Map<String, String>> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _allFaqs;
    return _allFaqs
        .where(
          (faq) =>
              faq['question']!.contains(_searchQuery) ||
              faq['answer']!.contains(_searchQuery),
        )
        .toList();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': user?.uid,
        'userEmail': user?.email,
        'message': _messageController.text.trim(),
        'createdAt': Timestamp.now(),
        'status': 'open',
      });

      if (mounted) {
        _messageController.clear();
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.message_sent_successfully,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(15),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        String errorMessage = AppLocalizations.of(context)!.message_send_error;
        if (e.toString().contains("permission-denied")) {
          errorMessage = "Send failed: No permissions (check Firestore rules)";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(15),
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _launchWhatsApp() async {
    final String? whatsappNumber = dotenv.env['WHATSAPP_NUMBER'];
    if (whatsappNumber == null) {
      debugPrint('WhatsApp number not configured in .env');
      return;
    }
    final Uri url = Uri.parse('https://wa.me/$whatsappNumber');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchEmail() async {
    final String? supportEmail = dotenv.env['SUPPORT_EMAIL'];
    if (supportEmail == null) {
      debugPrint('Support email not configured in .env');
      return;
    }
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': AppLocalizations.of(context)!.support_request,
      },
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Could not launch $emailLaunchUri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [_buildModernHeader()];
          },
          body: StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('merchants')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
            builder: (context, snapshot) {
              String? planName;
              if (snapshot.hasData && snapshot.data!.exists) {
                planName =
                    (snapshot.data!.data() as Map<String, dynamic>)['plan'];
              }
              final plan = SubscriptionPlan.fromString(planName);

              return TabBarView(
                children: [_buildFAQTab(), _buildContactTab(plan)],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1E3A8A),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                left: -50,
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    Text(
                      AppLocalizations.of(context)!.how_can_we_help,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged:
                            (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context)!.search_faq_hint,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.blueAccent,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.white,
          child: TabBar(
            labelColor: const Color(0xFF1E3A8A),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1E3A8A),
            indicatorWeight: 3,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.faq),
              Tab(text: AppLocalizations.of(context)!.contact_us),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQTab() {
    final faqs = _filteredFaqs;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final faq = faqs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFF3B82F6), width: 5),
                ),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  iconColor: const Color(0xFF3B82F6),
                  collapsedIconColor: Colors.grey,
                  title: Text(
                    faq['question']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 12),
                    Text(
                      faq['answer']!,
                      style: TextStyle(
                        color: Colors.blueGrey.shade700,
                        height: 1.6,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactTab(SubscriptionPlan plan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildQuickContact(
                context,
                icon: FontAwesomeIcons.whatsapp,
                title: AppLocalizations.of(context)!.whatsapp,
                color: const Color(0xFF10B981),
                onTap: _launchWhatsApp,
              ),
              const SizedBox(width: 15),
              _buildQuickContact(
                context,
                icon: FontAwesomeIcons.envelope,
                title: AppLocalizations.of(context)!.email,
                color: const Color(0xFF3B82F6),
                onTap: _launchEmail,
              ),
            ],
          ),
          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.envelope,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.send_direct_message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.message_hint,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF3B82F6),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                        (!plan.hasSpecialSupport &&
                                FirebaseAuth.instance.currentUser?.email !=
                                    dotenv.env['ADMIN_EMAIL'])
                            ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => SubscriptionPaywall(
                                        email:
                                            FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.email ??
                                            "",
                                        isTrialExpired: false,
                                      ),
                                ),
                              );
                            }
                            : (_isSending ? null : _sendMessage),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          plan.hasSpecialSupport
                              ? const Color(0xFF3B82F6)
                              : Colors.grey[400],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isSending
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              (plan.hasSpecialSupport ||
                                      FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.email ==
                                          dotenv.env['ADMIN_EMAIL'])
                                  ? AppLocalizations.of(context)!.send_now
                                  : AppLocalizations.of(
                                    context,
                                  )!.upgrade_for_support,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
                if (!plan.hasSpecialSupport &&
                    FirebaseAuth.instance.currentUser?.email !=
                        dotenv.env['ADMIN_EMAIL'])
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.pro_feature_only,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                if (FirebaseAuth.instance.currentUser?.email ==
                    dotenv.env['ADMIN_EMAIL'])
                  _buildAdminAccess(),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              AppLocalizations.of(context)!.follow_us,

              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                icon: FontAwesomeIcons.tiktok,
                color: Colors.black,
                onTap:
                    () => _launchSocial("https://tiktok.com/youssifelshafei"),
              ),

              const SizedBox(width: 15),
              _buildSocialButton(
                icon: FontAwesomeIcons.instagram,
                color: const Color(0xFFE4405F),
                onTap:
                    () => _launchSocial(
                      "https://www.instagram.com/invento_merchant/",
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickContact(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildAdminAccess() {
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminTicketsScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.open_admin_panel,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchSocial(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
