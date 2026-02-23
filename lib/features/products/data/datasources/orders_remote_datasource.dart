import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invento/features/orders/domain/entities/order_entity.dart';
import '../models/order_model.dart';

abstract class OrdersRemoteDataSource {
  Future<void> createOrder(OrderModel order);
  Future<List<OrderModel>> getOrders();
  Future<List<OrderModel>> getOrdersBySource(String source);
  Future<void> updateOrderStatus(String orderId, String newStatus);
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  OrdersRemoteDataSourceImpl({required this.firestore, required this.auth});

  CollectionReference get _ordersCollection => firestore.collection('orders');

  String get _currentUserId {
    final user = auth.currentUser;
    if (user == null) throw Exception("يجب تسجيل الدخول أولاً");
    return user.uid;
  }

  @override
  Future<void> createOrder(OrderModel order) async {
    final orderData = order.toDocument();
    orderData['userId'] = _currentUserId;
    await _ordersCollection.add(orderData);
  }

  @override
  Future<List<OrderModel>> getOrders() async {
    final userId = _currentUserId;

    final snapshot =
        await _ordersCollection.where('userId', isEqualTo: userId).get();

    final allOrders =
        snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();

    final activeOrders =
        allOrders.where((order) {
          return order.status != OrderStatus.cancelled;
        }).toList();

    activeOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return activeOrders;
  }

  @override
  Future<List<OrderModel>> getOrdersBySource(String source) async {
    final userId = _currentUserId;

    final snapshot =
        await _ordersCollection
            .where('userId', isEqualTo: userId)
            .where('source', isEqualTo: source)
            .get();

    final orders =
        snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();

    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final userId = _currentUserId;

    // Verify ownership before updating.
    final doc = await _ordersCollection.doc(orderId).get();
    if (!doc.exists) throw Exception("الطلب غير موجود.");

    final data = doc.data() as Map<String, dynamic>;
    if (data['userId'] != userId) {
      throw Exception("ليس لديك صلاحية تعديل هذا الطلب.");
    }

    await _ordersCollection.doc(orderId).update({'status': newStatus});
  }
}
