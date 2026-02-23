import 'package:invento/features/orders/domain/entities/order_entity.dart';

abstract class OrdersEvent {}

class LoadOrdersEvent extends OrdersEvent {}

class CreateOrderEvent extends OrdersEvent {
  final OrderEntity order;
  CreateOrderEvent(this.order);
}
