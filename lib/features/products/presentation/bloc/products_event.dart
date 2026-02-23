import 'dart:io';

import 'package:invento/features/products/data/models/product_model.dart';

abstract class ProductsEvent {}

class LoadProductsEvent extends ProductsEvent {}

class GetProductsEvent extends ProductsEvent {}

class AddProductEvent extends ProductsEvent {
  final ProductModel product;
  final File imageFile;

  AddProductEvent(this.product, this.imageFile);
}

class UpdateProductEvent extends ProductsEvent {
  final ProductModel product;
  UpdateProductEvent(this.product);
}

class DeleteProductEvent extends ProductsEvent {
  final String productId;
  DeleteProductEvent(this.productId);
}
