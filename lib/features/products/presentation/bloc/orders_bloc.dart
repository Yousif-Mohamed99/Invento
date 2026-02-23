import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invento/features/orders/domain/entities/order_entity.dart';
import 'package:invento/features/orders/domain/usecases/create_order_usecase.dart';
import 'package:invento/features/orders/domain/usecases/get_orders_usecase.dart';
import 'package:invento/features/orders/domain/usecases/sync_stock_usecase.dart';
import 'package:invento/features/products/presentation/bloc/orders_event.dart';
import 'package:invento/features/products/presentation/bloc/orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final GetOrdersUseCase getOrdersUseCase;
  final CreateOrderUseCase createOrderUseCase;
  final SyncStockUseCase syncStockUseCase;

  OrdersBloc({
    required this.getOrdersUseCase,
    required this.createOrderUseCase,
    required this.syncStockUseCase,
  }) : super(OrdersInitial()) {
    on<LoadOrdersEvent>((event, emit) async {
      emit(OrdersLoading());
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;

        if (userId == null) {
          emit(OrdersError("لم يتم العثور على مستخدم مسجل"));

          return;
        }

        final allOrders = await getOrdersUseCase.call();

        final activeOrders =
            allOrders.where((order) {
              return order.status != OrderStatus.cancelled;
            }).toList();

        final double todayEarnings = getOrdersUseCase.calculateDailyEarnings(
          activeOrders,
        );
        final int todayCount = getOrdersUseCase.countTodayOrders(activeOrders);

        emit(
          OrdersLoaded(
            orders: activeOrders,
            todayOrdersCount: todayCount,
            todayEarnings: todayEarnings,
          ),
        );
      } catch (e) {
        emit(OrdersError("فشل تحميل الطلبات: $e"));
      }
    });

    on<CreateOrderEvent>((event, emit) async {
      try {
        await createOrderUseCase.call(event.order);
        await syncStockUseCase.call(event.order);

        add(LoadOrdersEvent());
      } catch (e) {
        emit(OrdersError("فشل في إنشاء الطلب: ${e.toString()}"));
      }
    });
  }
}
