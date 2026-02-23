import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invento/features/orders/domain/entities/product_entity.dart';
import 'package:invento/features/orders/domain/usecases/add_product_usecase.dart';
import 'package:invento/features/orders/domain/usecases/delete_product_usecase.dart';
import 'package:invento/features/orders/domain/usecases/get_products_usecase.dart';
import 'package:invento/features/orders/domain/usecases/update_product_usecase.dart';
import 'package:invento/features/products/data/models/product_model.dart';
import 'products_event.dart';
import 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final GetProductsUseCase getProductsUseCase;
  final AddProductUseCase addProductUseCase;
  final UpdateProductUseCase updateProductUseCase;
  final DeleteProductUseCase deleteProductUseCase;

  ProductsBloc({
    required this.getProductsUseCase,
    required this.addProductUseCase,
    required this.updateProductUseCase,
    required this.deleteProductUseCase,
  }) : super(ProductsInitial()) {
    on<LoadProductsEvent>((event, emit) async {
      emit(ProductsLoading());
      try {
        final products = await getProductsUseCase();
        emit(ProductsLoaded(List<ProductEntity>.from(products)));
      } catch (e) {
        emit(ProductsError("عفواً، حدث خطأ أثناء تحميل المنتجات"));
      }
    });

    on<AddProductEvent>((event, emit) async {
      emit(ProductsLoading());
      try {
        String userId = FirebaseAuth.instance.currentUser!.uid;
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();

        Reference ref = FirebaseStorage.instance
            .ref()
            .child('products')
            .child(userId)
            .child('$fileName.jpg');

        UploadTask uploadTask = ref.putFile(event.imageFile);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        final updatedProduct = ProductModel(
          name: event.product.name,
          costPrice: event.product.costPrice,
          sellingPrice: event.product.sellingPrice,
          stockQuantity: event.product.stockQuantity,
          imageUrl: downloadUrl,
          category: event.product.category,
          sizes: event.product.sizes,
        );

        await addProductUseCase(updatedProduct);
        emit(ProductsSuccess());
        add(LoadProductsEvent());
      } catch (e) {
        emit(ProductsError("فشل إضافة المنتج: ${e.toString()}"));
      }
    });

    on<DeleteProductEvent>((event, emit) async {
      try {
        await deleteProductUseCase(event.productId);
        add(LoadProductsEvent());
      } catch (e) {
        emit(ProductsError("فشل حذف المنتج"));
      }
    });

    on<UpdateProductEvent>((event, emit) async {
      emit(ProductsLoading());
      try {
        await updateProductUseCase(event.product);
        emit(ProductsSuccess());
        add(LoadProductsEvent());
      } catch (e) {
        emit(ProductsError("فشل تحديث المنتج"));
      }
    });
  }
}
