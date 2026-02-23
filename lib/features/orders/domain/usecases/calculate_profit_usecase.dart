import '../entities/order_entity.dart';

class CalculateProfitUseCase {
  double executeSingleOrder(OrderEntity order) {
    if (order.status == OrderStatus.cancelled) return 0.0;

    double profit = 0;
    for (var item in order.items) {
      // الربح = (سعر البيع - التكلفة) * الكمية
      profit +=
          (item.priceAtTimeOfOrder - item.costPriceAtTimeOfOrder) *
          item.quantity;
    }
    return profit;
  }

  // حساب إجمالي أرباح قائمة (مثلاً الشهر) بعد استبعاد الملغي
  double executeTotal(List<OrderEntity> orders) {
    return orders
        .where((o) => o.status != OrderStatus.cancelled)
        .fold(0, (sum, order) => sum + executeSingleOrder(order));
  }
}
