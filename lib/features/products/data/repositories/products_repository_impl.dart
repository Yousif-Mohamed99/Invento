import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invento/features/orders/domain/entities/product_entity.dart';
import 'package:invento/features/orders/domain/repositories/products_repository.dart';
import 'package:invento/features/products/data/models/product_model.dart';
import 'package:invento/features/products/data/datasources/product_remote_datasource.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ProductEntity>> getProducts() async {
    return await remoteDataSource.getProducts();
  }

  @override
  Future<void> addProduct(ProductEntity product) async {
    final productModel = ProductModel(
      id: product.id,
      name: product.name,
      costPrice: product.costPrice,
      sellingPrice: product.sellingPrice,
      stockQuantity: product.stockQuantity,
      imageUrl: product.imageUrl,
      category: product.category,
      sizes: product.sizes,
    );

    return await remoteDataSource.addProduct(productModel);
  }

  @override
  Future<ProductEntity> getProductById(String id) async {
    final doc =
        await FirebaseFirestore.instance.collection('products').doc(id).get();
    if (doc.exists) {
      return ProductModel.fromSnapshot(doc);
    } else {
      throw Exception("المنتج غير موجود");
    }
  }

  @override
  Future<void> updateProductStock(String id, int newQuantity) async {
    return await remoteDataSource.updateProductStock(id, newQuantity);
  }

  @override
  Future<void> deleteProduct(String id) async {
    return await remoteDataSource.deleteProduct(id);
  }

  @override
  Future<void> updateProduct(ProductEntity product) async {
    final productModel = ProductModel(
      id: product.id,
      name: product.name,
      costPrice: product.costPrice,
      sellingPrice: product.sellingPrice,
      stockQuantity: product.stockQuantity,
      imageUrl: product.imageUrl,
      category: product.category,
      sizes: product.sizes,
    );

    return await remoteDataSource.updateProduct(productModel);
  }
}
