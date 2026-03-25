import '../repositories/orders_repository.dart';
import '../entities/order_entity.dart';

class GetOrdersUseCase {
  final OrdersRepository repository;

  GetOrdersUseCase(this.repository);

  Future<List<OrderEntity>> call() async {
    return await repository.getOrders();
  }

  // Calculate monthly profit (received or in-progress orders only - exclude cancelled)
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

  // Number of today's orders (exclude cancelled)
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
