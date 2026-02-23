import '../repositories/orders_repository.dart';
import '../entities/order_entity.dart';

class GetOrdersUseCase {
  final OrdersRepository repository;

  GetOrdersUseCase(this.repository);

  Future<List<OrderEntity>> call() async {
    return await repository.getOrders();
  }

  // حساب أرباح الشهر (المبيعات المستلمة فقط أو قيد التنفيذ - نستبعد الملغي)
  double calculateMonthlyEarnings(List<OrderEntity> orders) {
    final now = DateTime.now();
    return orders
        .where(
          (order) =>
              order.status != OrderStatus.cancelled &&
              order.createdAt.month == now.month &&
              order.createdAt.year == now.year,
        )
        .fold(0, (sum, item) => sum + item.totalAmount);
  }

  // عدد طلبات اليوم (نستبعد الملغي)
  int countTodayOrders(List<OrderEntity> orders) {
    final now = DateTime.now();
    return orders
        .where(
          (order) =>
              order.status != OrderStatus.cancelled &&
              order.createdAt.day == now.day &&
              order.createdAt.month == now.month,
        )
        .length;
  }

  double calculateDailyEarnings(List<OrderEntity> orders) {
    final now = DateTime.now();
    return orders
        .where(
          (o) => o.createdAt.day == now.day && o.createdAt.month == now.month,
        )
        .fold(0, (sum, item) => sum + item.totalAmount);
  }
}
