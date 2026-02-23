import 'package:invento/features/orders/domain/entities/product_entity.dart';

abstract class ProductsRepository {
  Future<List<ProductEntity>> getProducts();
  Future<void> addProduct(ProductEntity product);
  Future<void> deleteProduct(String id);
  Future<void> updateProduct(ProductEntity product);

  Future<ProductEntity?> getProductById(String id);

  Future<void> updateProductStock(String id, int newQuantity);
}
