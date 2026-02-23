import 'package:invento/features/orders/domain/entities/order_entity.dart';
import 'package:invento/features/products/data/models/activity_model.dart';

abstract class OrdersRepository {
  Future<List<OrderEntity>> getOrders();
  Future<void> createOrder(OrderEntity order);

  Future<List<OrderEntity>> filterOrdersBySource(OrderSource source);

  Stream<List<ActivityModel>> getActivitiesStream();

  Future<OrderEntity> getOrderById(String orderId);

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? trackingNumber,
  });

  Future<void> cancelOrder(OrderEntity order);

  Stream<List<OrderEntity>> getAllOrdersStream();
}
