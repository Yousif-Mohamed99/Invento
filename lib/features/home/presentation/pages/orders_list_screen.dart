import 'dart:async';

import 'package:flutter/material.dart';
import 'package:invento/core/injection_container.dart';
import 'package:invento/features/home/presentation/pages/order_details_screen.dart';
import 'package:invento/features/orders/domain/entities/order_entity.dart';
import 'package:invento/features/orders/domain/repositories/orders_repository.dart';
import 'package:timeago/timeago.dart' as timeago;

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  String searchQuery = "";
  String? selectedCity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            const Text("كل الطلبات"),
            StreamBuilder<List<OrderEntity>>(
              stream: sl<OrdersRepository>().getAllOrdersStream(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return Text(
                  "$count طلب نشط",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                );
              },
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // City Filter Dropdown
          StreamBuilder<List<OrderEntity>>(
            stream: sl<OrdersRepository>().getAllOrdersStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              // Get unique cities from the orders
              final Set<String> availableCities =
                  snapshot.data!
                      .where((order) => order.city.isNotEmpty)
                      .map((order) => order.city)
                      .toSet();

              if (availableCities.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // Light blue background
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(
                        0xFF2563EB,
                      ).withValues(alpha: 0.1), // Subtle blue border
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCity,
                      hint: const Text(
                        'المحافظة',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            "الكل",
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...availableCities.map(
                          (city) => DropdownMenuItem(
                            value: city,
                            child: Text(
                              city,
                              style: const TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCity = value;
                        });
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged:
                    (value) => setState(() => searchQuery = value.trim()),
                decoration: InputDecoration(
                  hintText: "ابحث برقم الطلب (ID)...",
                  hintStyle: const TextStyle(color: Colors.blueGrey),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF2563EB),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<OrderEntity>>(
        stream: sl<OrdersRepository>().getAllOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("لا توجد طلبات مسجلة بعد"));
          }

          // 1. الفلترة الأساسية (استبعاد الملغي)
          List<OrderEntity> orders =
              snapshot.data!.where((order) {
                return order.status != OrderStatus.cancelled &&
                    order.status.name != 'cancelled';
              }).toList();

          // 2. الفلترة حسب المحافظة
          if (selectedCity != null) {
            orders =
                orders.where((order) => order.city == selectedCity).toList();
          }

          if (searchQuery.isNotEmpty) {
            orders.sort((a, b) {
              // إذا كان الأوردر "أ" يطابق الـ ID، يطلع فوق
              bool aMatches = a.id!.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
              bool bMatches = b.id!.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );

              if (aMatches && !bMatches) return -1;
              if (!aMatches && bMatches) return 1;
              return 0;
            });
          }

          if (orders.isEmpty) return const Center(child: Text("لا توجد نتائج"));

          return ListView.builder(
            itemCount: orders.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemBuilder: (context, index) {
              final order = orders[index];

              bool isMatched =
                  searchQuery.isNotEmpty &&
                  order.id!.toLowerCase().contains(searchQuery.toLowerCase());

              final bool isPending = order.status == OrderStatus.pending;
              final Color statusColor =
                  isPending ? Colors.orange : Colors.green;
              final Color cardColor =
                  isMatched
                      ? const Color(0xFFEFF6FF)
                      : Colors.white; // Soft blue for match
              final Color borderColor =
                  isMatched ? const Color(0xFF2563EB) : Colors.transparent;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: isMatched ? 1.5 : 0,
                  ),
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
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  OrderDetailsScreen(orderId: order.id!),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color:
                                  isMatched
                                      ? const Color(
                                        0xFF2563EB,
                                      ).withValues(alpha: 0.1)
                                      : statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isMatched
                                  ? Icons.check_circle_rounded
                                  : Icons.local_mall_rounded,
                              color:
                                  isMatched
                                      ? const Color(0xFF2563EB)
                                      : statusColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        order.customerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      "#${order.id!.substring(0, 6)}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${order.totalAmount} ج.م",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                        fontSize: 14,
                                      ),
                                    ),
                                    RealTimeText(
                                      date: order.createdAt,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RealTimeText extends StatefulWidget {
  final DateTime date;
  final TextStyle? style;

  const RealTimeText({super.key, required this.date, this.style});

  @override
  State<RealTimeText> createState() => _RealTimeTextState();
}

class _RealTimeTextState extends State<RealTimeText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // تحديث كل دقيقة (60 ثانية)
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // إيقاف التايمر عند حذف الـ Widget من الشاشة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(timeago.format(widget.date, locale: 'ar'), style: widget.style);
  }
}
