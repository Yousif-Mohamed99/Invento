import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invento/features/orders/domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  OrderModel({
    super.id,
    required super.userId,
    required super.customerName,
    required super.customerPhone,
    required super.shippingAddress,
    required super.city,
    required super.items,
    required super.deliveryFee,
    required super.totalAmount,
    required super.status,
    required super.source,
    super.trackingNumber,
    required super.createdAt,
  });

  factory OrderModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      shippingAddress: data['shippingAddress'] ?? '',
      city: data['city'] ?? '',
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      trackingNumber: data['trackingNumber'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),

      source: OrderSource.values.firstWhere(
        (e) => e.name == data['source'],
        orElse: () => OrderSource.manual,
      ),

      items:
          (data['items'] as List)
              .map((i) => OrderItemModel.fromMap(i))
              .toList(),
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'shippingAddress': shippingAddress,
      'city': city,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'status': status.name,
      'source': source.name,
      'trackingNumber': trackingNumber,
      'createdAt': createdAt,

      'items':
          items.map((item) {
            if (item is OrderItemModel) return item.toMap();

            return OrderItemModel(
              productId: item.productId,
              productName: item.productName,
              quantity: item.quantity,
              priceAtTimeOfOrder: item.priceAtTimeOfOrder,
              costPriceAtTimeOfOrder: item.costPriceAtTimeOfOrder,
              selectedSize: item.selectedSize,
            ).toMap();
          }).toList(),
    };
  }
}

class OrderItemModel extends OrderItem {
  OrderItemModel({
    required super.productId,
    required super.productName,
    required super.quantity,
    required super.priceAtTimeOfOrder,
    required super.costPriceAtTimeOfOrder,
    super.selectedSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'priceAtTimeOfOrder': priceAtTimeOfOrder,
      'costPriceAtTimeOfOrder': costPriceAtTimeOfOrder,
      'selectedSize': selectedSize,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'],
      productName: map['productName'],
      quantity: map['quantity'],
      priceAtTimeOfOrder: (map['priceAtTimeOfOrder'] ?? 0.0).toDouble(),
      costPriceAtTimeOfOrder: (map['costPriceAtTimeOfOrder'] ?? 0.0).toDouble(),
      selectedSize: map['selectedSize'],
    );
  }
}
