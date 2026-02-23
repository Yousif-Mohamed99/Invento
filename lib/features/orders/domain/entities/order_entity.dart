import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, processing, shipped, delivered, cancelled }

enum OrderSource { instagram, facebook, tiktok, whatsapp, manual }

class OrderEntity {
  final String? id;
  final String userId;
  final String customerName;
  final String customerPhone;
  final String shippingAddress;
  final String city;
  final List<OrderItem> items;
  final double deliveryFee;
  final double totalAmount;
  final OrderStatus status;
  final OrderSource source;
  final String? trackingNumber;
  final DateTime createdAt;

  OrderEntity({
    this.id,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.shippingAddress,
    required this.city,
    required this.items,
    required this.deliveryFee,
    required this.totalAmount,
    required this.status,
    required this.source,
    this.trackingNumber,
    required this.createdAt,
  });

  factory OrderEntity.fromMap(Map<String, dynamic> map, String documentId) {
    return OrderEntity(
      id: documentId,
      userId: map['userId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      shippingAddress: map['shippingAddress'] ?? '',
      city: map['city'] ?? '',

      items:
          (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,

      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${map['status']}',
        orElse: () => OrderStatus.pending,
      ),
      source: OrderSource.values.firstWhere(
        (e) => e.toString() == 'OrderSource.${map['source']}',
        orElse: () => OrderSource.manual,
      ),
      trackingNumber: map['trackingNumber'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double priceAtTimeOfOrder;
  final double costPriceAtTimeOfOrder;
  final String? selectedSize;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceAtTimeOfOrder,
    required this.costPriceAtTimeOfOrder,
    this.selectedSize,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      priceAtTimeOfOrder:
          (map['priceAtTimeOfOrder'] as num?)?.toDouble() ?? 0.0,
      costPriceAtTimeOfOrder:
          (map['costPriceAtTimeOfOrder'] as num?)?.toDouble() ?? 0.0,
      selectedSize: map['selectedSize'],
    );
  }
}
