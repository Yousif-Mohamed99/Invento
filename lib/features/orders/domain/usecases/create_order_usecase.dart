import 'package:invento/features/orders/domain/repositories/orders_repository.dart';

import '../entities/order_entity.dart';

class CreateOrderUseCase {
  final OrdersRepository repository;

  CreateOrderUseCase(this.repository);

  Future<void> call(OrderEntity order) async {
    return await repository.createOrder(order);
  }
}
