import 'package:invento/features/orders/domain/entities/order_entity.dart';

abstract class OrdersState {}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<OrderEntity> orders;
  final int todayOrdersCount;
  final double todayEarnings;

  OrdersLoaded({
    required this.orders,
    this.todayOrdersCount = 0,
    this.todayEarnings = 0.0,
  });
}

class OrdersError extends OrdersState {
  final String message;
  OrdersError(this.message);
}
