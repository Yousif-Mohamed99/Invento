import 'package:invento/features/orders/domain/entities/product_entity.dart';
import 'package:equatable/equatable.dart';

abstract class ProductsState {}

class ProductsInitial extends ProductsState {}

class ProductsLoading extends ProductsState {}

class ProductsSuccess extends ProductsState {}

class ProductsLoaded extends ProductsState with EquatableMixin {
  final List<ProductEntity> products;
  ProductsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class ProductsError extends ProductsState {
  final String message;
  ProductsError(this.message);
}
