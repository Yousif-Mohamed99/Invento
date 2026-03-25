import '../entities/order_entity.dart';

class CalculateProfitUseCase {
  double executeSingleOrder(OrderEntity order) {
    if (order.status == OrderStatus.cancelled) return 0.0;

    double profit = 0;
    for (var item in order.items) {
      // Profit = (selling price - cost) * quantity
      profit +=
          (item.priceAtTimeOfOrder - item.costPriceAtTimeOfOrder) *
          item.quantity;
    }
    return profit;
  }

  // Calculate total profit for a list after excluding cancelled orders
  double executeTotal(List<OrderEntity> orders) {
    return orders
        .where((o) => o.status != OrderStatus.cancelled)
        .fold(0, (sum, order) => sum + executeSingleOrder(order));
  }
}
