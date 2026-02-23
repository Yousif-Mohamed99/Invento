import 'package:invento/features/orders/domain/entities/product_entity.dart';
import 'package:invento/features/orders/domain/repositories/products_repository.dart';

class UpdateProductUseCase {
  final ProductsRepository repository;

  UpdateProductUseCase({required this.repository});

  Future<void> call(ProductEntity product) async {
    return await repository.updateProduct(product);
  }
}
