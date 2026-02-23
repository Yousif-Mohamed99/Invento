import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invento/features/orders/domain/entities/product_entity.dart';

class SizeVariant {
  final String size;
  final int quantity;

  SizeVariant({required this.size, required this.quantity});

  Map<String, dynamic> toMap() => {'size': size, 'quantity': quantity};

  factory SizeVariant.fromMap(Map<String, dynamic> map) =>
      SizeVariant(size: map['size'] ?? '', quantity: map['quantity'] ?? 0);
}

class ProductModel extends ProductEntity {
  const ProductModel({
    super.id,
    required super.name,
    required super.costPrice,
    required super.sellingPrice,
    required super.stockQuantity,
    super.imageUrl,
    super.category,
    super.sizes,
  });

  factory ProductModel.fromSnapshot(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      costPrice: (data['costPrice'] ?? 0).toDouble(),
      sellingPrice: (data['sellingPrice'] ?? 0).toDouble(),
      stockQuantity: data['stockQuantity'] ?? 0,
      imageUrl: data['imageUrl'],
      category: data['category'],

      sizes:
          (data['sizes'] as List<dynamic>?)
              ?.map(
                (s) => ProductSize(
                  size: s['size'] ?? '',
                  quantity: s['quantity'] ?? 0,
                ),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'name': name,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'imageUrl': imageUrl,
      'category': category,
      'updatedAt': FieldValue.serverTimestamp(),
      'sizes':
          sizes?.map((s) => {'size': s.size, 'quantity': s.quantity}).toList(),
    };
  }
}
