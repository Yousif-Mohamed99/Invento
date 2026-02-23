import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invento/features/orders/domain/entities/product_entity.dart';
import 'package:invento/features/products/presentation/bloc/products_state.dart';
import '../../data/models/product_model.dart';
import '../bloc/products_bloc.dart';
import '../bloc/products_event.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(
      text: widget.product.sellingPrice.toString(),
    );

    // Calculate total stock from sizes if they exist
    int combinedStock = widget.product.stockQuantity;
    if (widget.product.sizes != null && widget.product.sizes!.isNotEmpty) {
      combinedStock = widget.product.sizes!.fold(
        0,
        (sum, item) => sum + item.quantity,
      );
    }

    _stockController = TextEditingController(text: combinedStock.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductsBloc, ProductsState>(
      listener: (context, state) {
        if (state is ProductsLoaded) {
          final currentProduct = state.products.firstWhere(
            (p) => p.id == widget.product.id,
            orElse: () => widget.product,
          );

          _nameController.text = currentProduct.name;
          _priceController.text = currentProduct.sellingPrice.toString();

          // Refresh total stock from sizes if updated
          int combinedStock = currentProduct.stockQuantity;
          if (currentProduct.sizes != null &&
              currentProduct.sizes!.isNotEmpty) {
            combinedStock = currentProduct.sizes!.fold(
              0,
              (sum, item) => sum + item.quantity,
            );
          }
          _stockController.text = combinedStock.toString();
        }
      },
      builder: (context, state) {
        ProductEntity currentProduct = widget.product;
        if (state is ProductsLoaded) {
          currentProduct = state.products.firstWhere(
            (p) => p.id == widget.product.id,
            orElse: () => widget.product,
          );
        }

        final hasSizes =
            currentProduct.sizes != null && currentProduct.sizes!.isNotEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductImageCard(currentProduct),
                      const SizedBox(height: 25),
                      _buildInfoCard(hasSizes),
                      const SizedBox(height: 25),
                      if (hasSizes) ...[
                        _buildSizesCard(currentProduct),
                        const SizedBox(height: 20),
                      ],
                      _buildActionButtons(context, currentProduct),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF1E3A8A),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          "تفاصيل المنتج",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
            size: 30,
          ),
          onPressed:
              () => _showDeleteDialog(context, context.read<ProductsBloc>()),
        ),
      ],
    );
  }

  Widget _buildProductImageCard(ProductEntity product) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child:
            product.imageUrl != null
                ? Image.network(
                  product.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => _buildPlaceholderImage(),
                )
                : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.blue.withValues(alpha: 0.05),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 80, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildInfoCard(bool hasSizes) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(Icons.info_outline, "البيانات الأساسية"),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _nameController,
            label: "اسم المنتج",
            icon: Icons.edit_note_rounded,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _priceController,
                  label: "سعر البيع",
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  suffix: "ج.م",
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildTextField(
                  controller: _stockController,
                  label: "إجمالي الكمية",
                  icon: Icons.inventory_2_outlined,
                  keyboardType: TextInputType.number,
                  readOnly: hasSizes,
                  helperText: hasSizes ? "تُحسب من المقاسات" : null,
                  fillColor: hasSizes ? const Color(0xFFF1F5F9) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? suffix,
    bool readOnly = false,
    String? helperText,
    Color? fillColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: readOnly ? Colors.blueGrey : Colors.black87,
          ),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
            suffixText: suffix,
            filled: fillColor != null,
            fillColor: fillColor,
            labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Text(
              helperText,
              style: const TextStyle(fontSize: 10, color: Colors.blueAccent),
            ),
          ),
      ],
    );
  }

  Widget _buildSizesCard(ProductEntity currentProduct) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(Icons.straighten_rounded, "توزيع المخزن"),
          const SizedBox(height: 15),
          _buildEnhancedSizesTable(currentProduct),
        ],
      ),
    );
  }

  Widget _buildEnhancedSizesTable(ProductEntity currentProduct) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: const [
                Expanded(
                  child: Text(
                    "المقاس",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Text(
                  "الكمية",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          ...currentProduct.sizes!.map(
            (s) => Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.size,
                      style: const TextStyle(color: Color(0xFF1E293B)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${s.quantity}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ProductEntity currentProduct,
  ) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showEditSizesDialog(),
          icon: const Icon(
            Icons.settings_suggest_outlined,
            color: Colors.white,
          ),
          label: const Text(
            "تعديل تفاصيل المقاسات",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF334155),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 55),
            backgroundColor: const Color(0xFF1E3A8A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            shadowColor: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
          ),
          onPressed: () {
            final double? price = double.tryParse(_priceController.text);
            final int? stock = int.tryParse(_stockController.text);

            if (price == null || stock == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("برجاء إدخال بيانات صحيحة"),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
              return;
            }

            final updatedProduct = ProductModel(
              id: widget.product.id,
              name: _nameController.text,
              sellingPrice: price,
              costPrice: widget.product.costPrice,
              stockQuantity: stock,
              category: widget.product.category,
              imageUrl: widget.product.imageUrl,
              sizes: currentProduct.sizes,
            );

            context.read<ProductsBloc>().add(
              UpdateProductEvent(updatedProduct),
            );
            Navigator.pop(context);
          },
          child: const Text(
            "حفظ التغييرات",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(
    BuildContext parentContext,
    ProductsBloc productsBloc,
  ) {
    showDialog(
      context: parentContext,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 10),
                Text("حذف المنتج؟"),
              ],
            ),
            content: const Text(
              "هل أنت متأكد من حذف هذا المنتج؟ لا يمكن التراجع عن هذا الإجراء.",
              style: TextStyle(color: Colors.blueGrey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "إلغاء",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  productsBloc.add(DeleteProductEvent(widget.product.id!));
                  Navigator.pop(context);
                  Navigator.pop(parentContext);
                },
                child: const Text(
                  "حذف نهائي",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showEditSizesDialog() {
    List<ProductSize> tempSizes = List.from(widget.product.sizes ?? []);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: const [
                    Icon(Icons.straighten, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 10),
                    Text(
                      "تعديل المقاسات",
                      style: TextStyle(color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: tempSizes.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: tempSizes[index].size,
                                      decoration: InputDecoration(
                                        hintText: "المقاس",
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onChanged:
                                          (val) =>
                                              tempSizes[index] = ProductSize(
                                                size: val,
                                                quantity:
                                                    tempSizes[index].quantity,
                                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue:
                                          tempSizes[index].quantity.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: "الكمية",
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onChanged:
                                          (val) =>
                                              tempSizes[index] = ProductSize(
                                                size: tempSizes[index].size,
                                                quantity:
                                                    int.tryParse(val) ?? 0,
                                              ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed:
                                        () => setDialogState(
                                          () => tempSizes.removeAt(index),
                                        ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            tempSizes.add(
                              const ProductSize(size: "", quantity: 0),
                            );
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: const Text("إضافة مقاس جديد"),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "إلغاء",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      int newTotalStock = tempSizes.fold(
                        0,
                        (sum, item) => sum + item.quantity,
                      );

                      setState(() {
                        widget.product.sizes?.clear();
                        widget.product.sizes?.addAll(tempSizes);
                        _stockController.text = newTotalStock.toString();
                      });

                      Navigator.pop(context);
                    },
                    child: const Text(
                      "حفظ",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }
}
