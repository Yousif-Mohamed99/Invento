import 'package:invento/features/orders/domain/entities/product_entity.dart';
import 'package:invento/features/orders/domain/repositories/products_repository.dart';
import 'package:invento/features/products/data/models/product_model.dart';

import '../entities/order_entity.dart';

class SyncStockUseCase {
  final ProductsRepository productsRepository;
  SyncStockUseCase(this.productsRepository);

  Future<void> call(OrderEntity order) async {
    for (var item in order.items) {
      final product = await productsRepository.getProductById(item.productId);

      if (product != null) {
        // 1. حساب الكمية الإجمالية الجديدة
        final newTotalQuantity = product.stockQuantity - item.quantity;

        // 2. تحديث قائمة المقاسات (خصم الكمية من المقاس المختار)
        List<ProductSize>? updatedSizes;
        if (product.sizes != null && item.selectedSize != null) {
          updatedSizes =
              product.sizes!.map((s) {
                if (s.size == item.selectedSize) {
                  return ProductSize(
                    size: s.size,
                    quantity: s.quantity - item.quantity,
                  );
                }
                return s;
              }).toList();
        }

        // 3. تحديث المنتج بالبيانات الجديدة (الإجمالي + توزيع المقاسات)
        final updatedProduct = ProductModel(
          id: product.id,
          name: product.name,
          costPrice: product.costPrice,
          sellingPrice: product.sellingPrice,
          stockQuantity: newTotalQuantity,
          imageUrl: product.imageUrl,
          category: product.category,
          sizes: updatedSizes,
        );

        await productsRepository.updateProduct(updatedProduct);
      }
    }
  }
}
