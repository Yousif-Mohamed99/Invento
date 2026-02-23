import 'package:flutter/material.dart';
import 'package:invento/features/orders/domain/entities/order_entity.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderInvoiceScreen extends StatelessWidget {
  final OrderEntity order;

  const OrderInvoiceScreen({super.key, required this.order});

  void _shareViaWhatsApp(BuildContext context) async {
    final String dateStr =
        "${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}";

    // Construct the WhatsApp message body
    final StringBuffer sb = StringBuffer();
    sb.writeln("📋 *بوليصة شحن طلب جديد*");
    sb.writeln("━━━━━━━━━━━━━━━");
    sb.writeln("🆔 *رقم الطلب:* ${order.id!.substring(0, 8)}...");
    sb.writeln("📅 *التاريخ:* $dateStr");
    sb.writeln("");
    sb.writeln("👤 *بيانات العميل:*");
    sb.writeln("الاسم: ${order.customerName}");
    sb.writeln("رقم الهاتف: ${order.customerPhone}");
    sb.writeln("المحافظة: ${order.city}");
    sb.writeln("العنوان: ${order.shippingAddress}");
    sb.writeln("");
    sb.writeln("📦 *تفاصيل المنتجات:*");

    for (var item in order.items) {
      String sizeTxt =
          item.selectedSize != null ? " (مقاس: ${item.selectedSize})" : "";
      sb.writeln("- ${item.quantity}x ${item.productName}$sizeTxt");
    }

    sb.writeln("━━━━━━━━━━━━━━━");
    sb.writeln(
      "💰 *إجمالي المنتجات:* ${order.totalAmount - order.deliveryFee} ج.م",
    );
    sb.writeln("🚚 *مصاريف الشحن:* ${order.deliveryFee} ج.م");
    sb.writeln("💵 *الإجمالي الكلي:* *${order.totalAmount} ج.م*");
    sb.writeln("━━━━━━━━━━━━━━━");
    sb.writeln("✨ شكراً لتعاملك معنا!");

    final String encodedMsg = Uri.encodeComponent(sb.toString());

    // Ensure phone number has country code. Assuming Egypt (+20) if starts with 01
    String phone = order.customerPhone.trim();
    if (phone.startsWith('01')) {
      phone = '+20${phone.substring(1)}';
    }

    final Uri whatsappUrl = Uri.parse(
      "whatsapp://send?phone=$phone&text=$encodedMsg",
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        // Fallback to web WhatsApp if app is not installed
        final Uri webUrl = Uri.parse("https://wa.me/$phone?text=$encodedMsg");
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "لا يمكن فتح وتساب، الرجاء التأكد من تثبيت التطبيق.",
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("حدث خطأ أثناء محاولة فتح واتساب.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String dateStr =
        "${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "بوليصة الشحن",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Receipt Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "طلب #${order.id!.substring(0, 6)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: Colors.blue.shade100,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Details
                        const Text(
                          "بيانات العميل",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.person,
                          "الاسم",
                          order.customerName,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          Icons.phone,
                          "الهاتف",
                          order.customerPhone,
                          isPhone: true,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          Icons.location_city,
                          "المحافظة",
                          order.city,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          Icons.map,
                          "العنوان",
                          order.shippingAddress,
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child:
                              Divider(), // Note: Flutter Divider doesn't support solid dashed out of the box, standard solid is fine here
                        ),

                        // Products
                        const Text(
                          "المنتجات",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...order.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "${item.quantity}x ${item.productName} ${item.selectedSize != null ? '(${item.selectedSize})' : ''}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${item.quantity * item.priceAtTimeOfOrder} ج.م",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(),
                        ),

                        _buildFinancialRow(
                          "إجمالي المنتجات",
                          order.totalAmount - order.deliveryFee,
                        ),
                        const SizedBox(height: 8),
                        _buildFinancialRow("مصاريف الشحن", order.deliveryFee),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "الإجمالي الكلي",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              Text(
                                "${order.totalAmount} ج.م",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Zigzag Bottom Edge effect (simplistic via decoration)
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _shareViaWhatsApp(context),
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text(
                  "مشاركة بوليصة الشحن عبر واتساب",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "رجوع",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isPhone = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade300),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            "$label:",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontFamily: isPhone ? 'monospace' : null,
              letterSpacing: isPhone ? 1.2 : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialRow(String title, num amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Text(
          "$amount ج.م",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}
