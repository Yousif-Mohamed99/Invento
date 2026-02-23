import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invento/features/auth/domain/repositories/auth_repository.dart';
import 'package:invento/features/auth/domain/repositories/auth_repository_impl.dart';
import 'package:invento/features/auth/domain/usecase/login_usecase.dart';
import 'package:invento/features/auth/domain/usecase/register_usecase.dart';
import 'package:invento/features/auth/domain/usecase/reset_password_usecase.dart';
import 'package:invento/features/auth/domain/usecase/google_sign_in_usecase.dart';
import 'package:invento/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:invento/features/orders/domain/repositories/orders_repository_impl.dart';
import 'package:invento/features/orders/domain/repositories/products_repository.dart';
import 'package:invento/features/orders/domain/usecases/add_product_usecase.dart';
import 'package:invento/features/orders/domain/usecases/create_order_usecase.dart';
import 'package:invento/features/orders/domain/usecases/delete_product_usecase.dart';
import 'package:invento/features/orders/domain/usecases/get_orders_usecase.dart';
import 'package:invento/features/orders/domain/usecases/get_products_usecase.dart';
import 'package:invento/features/orders/domain/usecases/update_product_usecase.dart';
import 'package:invento/features/products/data/datasources/orders_remote_datasource.dart';
import 'package:invento/features/products/presentation/bloc/orders_bloc.dart';
import '../../features/products/data/datasources/product_remote_datasource.dart';
import '../../features/products/data/repositories/products_repository_impl.dart';
import '../../features/products/presentation/bloc/products_bloc.dart';
import '../../features/orders/domain/repositories/orders_repository.dart';
import '../../features/orders/domain/usecases/sync_stock_usecase.dart';
import '../../features/orders/domain/usecases/calculate_profit_usecase.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! -------- Feature: Auth --------
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      resetPasswordUseCase: sl(),
      googleSignInUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => GoogleSignInUseCase(sl()));

  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(firebaseAuth: sl(), firestore: sl()),
  );

  //! -------- Feature: Products --------
  sl.registerFactory(
    () => ProductsBloc(
      getProductsUseCase: sl(),
      addProductUseCase: sl(),
      updateProductUseCase: sl(),
      deleteProductUseCase: sl(),
    ),
  );

  // Use Cases لمنتجات
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(repository: sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(repository: sl()));

  // Repository & DataSource
  sl.registerLazySingleton<ProductsRepository>(
    () => ProductsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(firestore: sl(), auth: sl()),
  );

  //! -------- Feature: Orders --------
  sl.registerFactory(
    () => OrdersBloc(
      getOrdersUseCase: sl(),
      createOrderUseCase: sl(),
      syncStockUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetOrdersUseCase(sl()));
  sl.registerLazySingleton(() => CreateOrderUseCase(sl()));
  sl.registerLazySingleton(() => SyncStockUseCase(sl()));
  sl.registerLazySingleton(() => CalculateProfitUseCase());

  sl.registerLazySingleton<OrdersRepository>(
    () => OrdersRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<OrdersRemoteDataSource>(
    () => OrdersRemoteDataSourceImpl(firestore: sl(), auth: sl()),
  );

  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton(() => FirebaseFirestore.instance);
  }

  if (!sl.isRegistered<FirebaseAuth>()) {
    sl.registerLazySingleton(() => FirebaseAuth.instance);
  }
}
