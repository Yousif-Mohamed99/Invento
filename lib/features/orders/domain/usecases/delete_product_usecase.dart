import 'package:invento/features/orders/domain/repositories/products_repository.dart';

class DeleteProductUseCase {
  final ProductsRepository repository;

  DeleteProductUseCase({required this.repository});

  Future<void> call(String id) async {
    return await repository.deleteProduct(id);
  }
}
