import 'package:equatable/equatable.dart';

class ProductSize extends Equatable {
  final String size;
  final int quantity;

  const ProductSize({required this.size, required this.quantity});

  @override
  List<Object?> get props => [size, quantity];

  Map<String, dynamic> toMap() => {'size': size, 'quantity': quantity};

  factory ProductSize.fromMap(Map<String, dynamic> map) {
    return ProductSize(size: map['size'] ?? '', quantity: map['quantity'] ?? 0);
  }
}

class ProductEntity extends Equatable {
  final String? id;
  final String name;
  final double costPrice; // سعر التكلفة (عشان احسب ارباح)
  final double sellingPrice; // سعر البيع
  final int stockQuantity; // الكمية في المخزن
  final String? imageUrl; // صورة المنتج
  final String? category;
  final List<ProductSize>? sizes;

  @override
  List<Object?> get props => [id, name, stockQuantity, sizes];

  const ProductEntity({
    this.id,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.imageUrl,
    required this.category,
    this.sizes,
  });

  int get totalStock {
    if (sizes == null || sizes!.isEmpty) return stockQuantity;
    return sizes!.fold(0, (sum, item) => sum + item.quantity);
  }
}
