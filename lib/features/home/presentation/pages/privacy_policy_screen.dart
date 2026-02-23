import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "سياسة الخصوصية",
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
              title: "مقدمة",
              content:
                  "مرحباً بك في Invento.\n\n"
                  "نحن نلتزم بحماية خصوصية بياناتك وتوفير بيئة آمنة لإدارة تجارتك. توضح هذه السياسة كيف نجمع ونستخدم بياناتك بشكل شفاف.",
            ),

            _buildCard(
              title: "1. البيانات التي نجمعها",
              content:
                  "• بيانات الهوية: (الاسم، البريد الإلكتروني، واسم المتجر).\n"
                  "• بيانات التجارة: (المنتجات، المخازن، والطلبات) لتسهيل إدارتها.\n"
                  "• بيانات التواصل: رقم الهاتف في حال التواصل مع الدعم الفني.",
            ),

            _buildCard(
              title: "2. كيف نستخدم بياناتك؟",
              content:
                  "نستخدم البيانات لإدارة حسابك، توفير ميزات التطبيق، والتواصل معك بخصوص اشتراكك الشهري أو لتقديم الدعم الفني والتقني.",
            ),

            _buildCard(
              title: "3. طرق الدفع وتفعيل الاشتراك",
              content:
                  "يتم تفعيل الاشتراك حالياً من خلال التواصل المباشر مع الدعم الفني عبر (واتساب).\n\n"
                  "بمجرد تأكيد عملية التحويل، يتم تفعيل حسابك يدوياً. نحن لا نطلب منك أي بيانات سرية "
                  "مثل أرقام الفيزا أو كلمات مرور البنك داخل التطبيق.",
            ),

            _buildCard(
              title: "4. أمان البيانات",
              content:
                  "يتم تخزين جميع البيانات بشكل مشفر وآمن عبر خوادم Google Firebase، ونحرص على تحديث أنظمة الأمان بشكل دوري لضمان أقصى حماية.",
            ),

            _buildCard(
              title: "5. الفترة التجريبية والاشتراك",
              content:
                  "يمنح Invento كل مستخدم جديد فترة تجريبية لمدة 7 أيام. "
                  "بعد انتهاء هذه الفترة، يتوقف التطبيق تلقائياً، ويجب التواصل مع الإدارة عبر واتساب "
                  "لتجديد الاشتراك الشهري للاستمرار في الوصول لبيانات مخزنك.",
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
                  "فهمت ذلك، رجوع",
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
