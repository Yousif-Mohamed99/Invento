import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invento/features/products/data/models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel?> getProductById(String id);
  Future<void> updateProductStock(String id, int newQuantity);
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ProductRemoteDataSourceImpl({required this.firestore, required this.auth});

  CollectionReference get _productsCollection =>
      firestore.collection('products');

  String get _currentUserId {
    final user = auth.currentUser;
    if (user == null) throw Exception("يجب تسجيل الدخول أولاً");
    return user.uid;
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    try {
      final data = product.toDocument();
      data['userId'] = _currentUserId;
      data['createdAt'] = FieldValue.serverTimestamp();

      await _productsCollection.add(data);
    } catch (e) {
      throw Exception("خطأ في إضافة المنتج: $e");
    }
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final snapshot =
          await _productsCollection
              .where('userId', isEqualTo: _currentUserId)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception("فشل جلب المنتجات: $e");
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final data = product.toDocument();
    data['userId'] = _currentUserId;
    await _productsCollection.doc(product.id).update(data);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _productsCollection.doc(id).delete();
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final doc = await _productsCollection.doc(id).get();
    return doc.exists ? ProductModel.fromSnapshot(doc) : null;
  }

  @override
  Future<void> updateProductStock(String id, int newQuantity) async {
    await _productsCollection.doc(id).update({'stockQuantity': newQuantity});
  }
}
