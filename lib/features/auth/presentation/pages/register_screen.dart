import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invento/features/home/presentation/pages/main_wrapper.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isAgreed = false;

  String _selectedCity = 'القاهرة';
  final List<String> _cities = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'المنصورة',
    'طنطا',
    'أسيوط',
  ];

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "تسجيل تاجر جديد",
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
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainWrapper()),
              (route) => false,
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                const Text(
                  "أنشئ حساب تاجرك الآن",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 30),

                _buildTextFormField(
                  controller: _storeNameController,
                  label: "اسم المتجر / البراند",
                  icon: Icons.store_outlined,
                ),
                const SizedBox(height: 15),

                _buildTextFormField(
                  controller: _emailController,
                  label: "البريد الإلكتروني",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),

                _buildTextFormField(
                  controller: _passwordController,
                  label: "كلمة المرور",
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF2563EB),
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: "المحافظة",
                    labelStyle: const TextStyle(color: Colors.blueGrey),
                    prefixIcon: const Icon(
                      Icons.location_city_outlined,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18.0,
                      horizontal: 16.0,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 2,
                      ),
                    ),
                  ),
                  items:
                      _cities
                          .map(
                            (city) => DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _selectedCity = val!),
                ),
                const SizedBox(height: 15),

                _buildTextFormField(
                  controller: _addressController,
                  label: "عنوان المخزن بالتفصيل",
                  icon: Icons.map_outlined,
                ),
                const SizedBox(height: 30),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow:
                            _isAgreed
                                ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1E3A8A,
                                    ).withValues(alpha: 0.25),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                                : null,
                        gradient:
                            _isAgreed
                                ? const LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF1E3A8A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                : null,
                        color: _isAgreed ? null : Colors.grey.shade400,
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
                        onPressed:
                            _isAgreed
                                ? () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthBloc>().add(
                                      SignUpRequested(
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                        storeName: _storeNameController.text,
                                        city: _selectedCity,
                                        address: _addressController.text,
                                      ),
                                    );
                                  }
                                }
                                : null,
                        child: const Text(
                          "إنشاء حسابي الآن",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _isAgreed,
                      onChanged: (val) => setState(() => _isAgreed = val!),
                      activeColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showPrivacyPolicy(context),
                        child: const Text(
                          "Invento أوافق على سياسة خصوصية",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1E3A8A),
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // const Padding(
                //   padding: EdgeInsets.symmetric(vertical: 10.0),
                //   child: Divider(thickness: 1),
                // ),

                // const Text(
                //   "أو سجل بواسطة",
                //   textAlign: TextAlign.center,
                //   style: TextStyle(color: Colors.blueGrey, fontSize: 13),
                // ),
                const SizedBox(height: 15),

                // Google Register Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    context.read<AuthBloc>().add(GoogleSignInRequested());
                  },
                  icon: const Icon(
                    FontAwesomeIcons.google,
                    color: Color(0xFFEA4335),
                    size: 18,
                  ),
                  label: const Text(
                    "التسجيل بواسطة جوجل",
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(thickness: 1),
                ),

                const Text(
                  "تواصل معنا",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialIcon(
                      icon: FontAwesomeIcons.facebook,
                      color: const Color(0xFF1877F2),
                      url: "https://facebook.com/merchant_hub",
                    ),
                    const SizedBox(width: 20),
                    _buildSocialIcon(
                      icon: FontAwesomeIcons.instagram,
                      color: const Color(0xFFE4405F),
                      url: "https://www.instagram.com/hub.merchant/",
                    ),
                    const SizedBox(width: 20),
                    _buildSocialIcon(
                      icon: FontAwesomeIcons.whatsapp,
                      color: const Color(0xFF25D366),
                      url: "https://wa.me/201551279642",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey),
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 22),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 16.0,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      validator: (v) => v!.isEmpty ? "هذا الحقل مطلوب" : null,
    );
  }

  Widget _buildSocialIcon({
    required IconData icon,
    required Color color,
    required String url,
  }) {
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}

void _showPrivacyPolicy(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // عشان تأخد مساحة كويسة
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7, // تفتح لغاية 70% من الشاشة
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "سياسة خصوصية Invento",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const Text(
                    "1. جمع البيانات:\nنجمع اسم المتجر، البريد الإلكتروني، وعنوان المخزن لتوفير خدمات الإدارة والمحاسبة.\n\n"
                    "2. أمان البيانات:\nبياناتك مشفرة ومخزنة عبر خوادم Google Firebase الآمنة، ولا يمكن لأي طرف ثالث الوصول إليها.\n\n"
                    "3. الفترة التجريبية والاشتراك:\nيمنح Invento فترة تجريبية 7 أيام، بعدها يتطلب التطبيق اشتراكاً شهرياً بقيمة 400 ج.م.\n\n"
                    "4. إدارة الحساب:\nيمكنك تعديل بياناتك أو طلب حذف حسابك نهائياً عبر التواصل مع الدعم الفني مباشرة من داخل التطبيق.\n\n"
                    "5. الدفع:\nتتم عمليات الدفع عبر بوابات دفع معتمدة، ولا نقوم بتخزين أي بيانات حساسة لبطاقاتك الائتمانية.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("فهمت ذلك"),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
