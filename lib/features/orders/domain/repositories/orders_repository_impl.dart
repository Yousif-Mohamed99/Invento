import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invento/features/products/data/models/activity_model.dart';

import 'package:rxdart/rxdart.dart';

import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/orders_repository.dart';

import 'package:invento/features/products/data/datasources/orders_remote_datasource.dart';
import 'package:invento/features/products/data/models/order_model.dart';
import 'package:invento/features/products/data/models/product_model.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource remoteDataSource;
  OrdersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<OrderEntity>> getOrders() async {
    return await remoteDataSource.getOrders();
  }

  @override
  Future<void> createOrder(OrderEntity order) async {
    final orderModel = OrderModel(
      id: order.id,
      userId: order.userId,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      shippingAddress: order.shippingAddress,
      city: order.city,
      deliveryFee: order.deliveryFee,
      totalAmount: order.totalAmount,
      status: order.status,
      source: order.source,
      createdAt: order.createdAt,
      items:
          order.items
              .map(
                (item) => OrderItemModel(
                  productId: item.productId,
                  productName: item.productName,
                  quantity: item.quantity,
                  priceAtTimeOfOrder: item.priceAtTimeOfOrder,
                  costPriceAtTimeOfOrder: item.costPriceAtTimeOfOrder,
                ),
              )
              .toList(),
    );

    await remoteDataSource.createOrder(orderModel);
  }

  @override
  Future<List<OrderEntity>> filterOrdersBySource(OrderSource source) async {
    return await remoteDataSource.getOrdersBySource(source.name);
  }

  @override
  Stream<List<ActivityModel>> getActivitiesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    final userId = user.uid;

    final ordersStream =
        FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .snapshots();

    final stockStream =
        FirebaseFirestore.instance
            .collection('products')
            .where('userId', isEqualTo: userId)
            .snapshots();

    return Rx.combineLatest2(ordersStream, stockStream, (
      QuerySnapshot ordersSnap,
      QuerySnapshot productsSnap,
    ) {
      final List<ActivityModel> activities = [];

      final pendingOrders =
          ordersSnap.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'pending'; // فلترة يدوي
          }).toList();

      for (var doc in pendingOrders) {
        final data = doc.data() as Map<String, dynamic>;
        activities.add(
          ActivityModel(
            id: "order_${doc.id}", // Add unique ID
            title: "أوردر جديد: ${data['customerName']}",
            subtitle: "أوردر جديد ينتظر المراجعة والتحضير",
            timestamp:
                (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
            type: ActivityType.newOrder,
            referenceId: doc.id,
          ),
        );
      }

      final lowStockProducts =
          productsSnap.docs.where((doc) {
            final product = ProductModel.fromSnapshot(doc);
            return product.totalStock <= 5;
          }).toList();

      for (var doc in lowStockProducts) {
        final data = doc.data() as Map<String, dynamic>;
        final product = ProductModel.fromSnapshot(doc);
        final DateTime activityTime =
            data['updatedAt'] != null
                ? (data['updatedAt'] as Timestamp).toDate()
                : (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate();

        activities.add(
          ActivityModel(
            id: "stock_${doc.id}",
            title: "تنبيه مخزن: ${product.name}",
            subtitle: "الكمية المتبقية حرجة جداً (${product.totalStock} قطعة)",
            timestamp: activityTime,
            type: ActivityType.lowStock,
            referenceId: doc.id,
          ),
        );
      }

      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return activities.take(5).toList();
    });
  }

  @override
  Future<OrderEntity> getOrderById(String orderId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .get();

    final data = doc.data();
    if (data == null || data['userId'] != userId) {
      throw Exception("غير مصرح لك بالوصول لهذا الطلب");
    }

    return OrderEntity.fromMap(data, doc.id);
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? trackingNumber,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    try {
      DocumentReference orderRef = firestore.collection('orders').doc(orderId);
      DocumentSnapshot orderSnap = await orderRef.get();

      if (!orderSnap.exists) throw Exception("الطلب غير موجود");

      final orderData = orderSnap.data() as Map<String, dynamic>;
      final List items = orderData['items'] ?? [];

      batch.update(orderRef, {
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
        if (trackingNumber != null) 'trackingNumber': trackingNumber,
      });

      if (newStatus == OrderStatus.shipped) {
        for (var item in items) {
          String productId = item['productId'];
          int quantitySold = item['quantity'];
          String? selectedSize = item['selectedSize'];

          DocumentReference productRef = firestore
              .collection('products')
              .doc(productId);

          DocumentSnapshot productSnap = await productRef.get();
          if (productSnap.exists) {
            final productData = productSnap.data() as Map<String, dynamic>;

            batch.update(productRef, {
              'stockQuantity': FieldValue.increment(-quantitySold),
              'updatedAt': FieldValue.serverTimestamp(),
            });

            if (productData.containsKey('sizes') && selectedSize != null) {
              List<dynamic> sizesList = List.from(productData['sizes']);

              bool sizeFound = false;
              for (var i = 0; i < sizesList.length; i++) {
                if (sizesList[i]['size'] == selectedSize) {
                  sizesList[i]['quantity'] =
                      (sizesList[i]['quantity'] as int) - quantitySold;
                  sizeFound = true;
                  break;
                }
              }

              if (sizeFound) {
                batch.update(productRef, {'sizes': sizesList});
              }
            }
          }
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception("فشل التحديث: $e");
    }
  }

  @override
  Future<void> cancelOrder(OrderEntity order) async {
    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.runTransaction((transaction) async {
        // 1. تجهيز مراجع المستندات (References)
        DocumentReference orderRef = firestore
            .collection('orders')
            .doc(order.id);

        // سنقوم بجلب بيانات كل المنتجات أولاً (القراءة)
        Map<String, DocumentSnapshot> productSnapshots = {};
        for (var item in order.items) {
          DocumentReference productRef = firestore
              .collection('products')
              .doc(item.productId);
          productSnapshots[item.productId] = await transaction.get(productRef);
        }

        // 2. الآن نبدأ عمليات الكتابة (Writes) بعد انتهاء كل القراءات

        // تحديث حالة الأوردر
        transaction.update(orderRef, {
          'status': OrderStatus.cancelled.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // تحديث المنتجات
        for (var item in order.items) {
          final productSnap = productSnapshots[item.productId];

          if (productSnap != null && productSnap.exists) {
            final productData = productSnap.data() as Map<String, dynamic>;
            int totalStock = productData['stockQuantity'] ?? 0;
            List<dynamic> sizesList = List.from(productData['sizes'] ?? []);

            // تحديث المقاسات داخل القائمة
            for (var i = 0; i < sizesList.length; i++) {
              if (sizesList[i]['size'] == item.selectedSize) {
                sizesList[i]['quantity'] =
                    (sizesList[i]['quantity'] as int) + item.quantity;
                break;
              }
            }

            // تنفيذ الكتابة
            transaction.update(productSnap.reference, {
              'stockQuantity': totalStock + item.quantity,
              'sizes': sizesList,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });
    } catch (e) {
      throw Exception("فشل إلغاء الطلب وإرجاع المخزن");
    }
  }

  @override
  Stream<List<OrderEntity>> getAllOrdersStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final orders =
              snapshot.docs.map((doc) {
                return OrderModel.fromSnapshot(doc);
              }).toList();

          final activeOrders =
              orders.where((order) {
                return order.status != OrderStatus.cancelled;
              }).toList();

          // ترتيب الأحدث أولاً
          activeOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return activeOrders;
        });
  }
}
