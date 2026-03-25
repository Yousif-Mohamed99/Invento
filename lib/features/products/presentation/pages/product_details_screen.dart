import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invento/features/orders/domain/entities/product_entity.dart';
import 'package:invento/features/products/presentation/bloc/products_state.dart';
import '../../data/models/product_model.dart';
import '../bloc/products_bloc.dart';
import '../bloc/products_event.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  late List<ProductSize> _currentSizes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(
      text: widget.product.sellingPrice.toString(),
    );

    // Initialize sizes from product
    _currentSizes =
        widget.product.sizes != null
            ? List<ProductSize>.from(widget.product.sizes!)
            : [];

    // Calculate total stock from sizes if they exist
    int combinedStock = widget.product.stockQuantity;
    if (_currentSizes.isNotEmpty) {
      combinedStock = _currentSizes.fold(0, (sum, item) => sum + item.quantity);
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

          // Update current sizes from product
          if (currentProduct.sizes != null &&
              currentProduct.sizes!.isNotEmpty) {
            _currentSizes = List<ProductSize>.from(currentProduct.sizes!);
          }

          // Refresh total stock from current sizes
          int combinedStock = currentProduct.stockQuantity;
          if (_currentSizes.isNotEmpty) {
            combinedStock = _currentSizes.fold(
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

        final hasSizes = _currentSizes.isNotEmpty;

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
                        _buildSizesCard(),
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
        title: Text(
          AppLocalizations.of(context)!.product_details,
          style: const TextStyle(
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
                  cacheHeight: 500,
                  cacheWidth: 500,
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
          _buildCardTitle(Icons.info_outline, AppLocalizations.of(context)!.basic_info),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _nameController,
            label: AppLocalizations.of(context)!.product_name,
            icon: Icons.edit_note_rounded,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _priceController,
                  label: AppLocalizations.of(context)!.selling_price,
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  suffix: AppLocalizations.of(context)!.egp,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildTextField(
                  controller: _stockController,
                  label: AppLocalizations.of(context)!.total_quantity,
                  icon: Icons.inventory_2_outlined,
                  keyboardType: TextInputType.number,
                  readOnly: hasSizes,
                  helperText: hasSizes ? AppLocalizations.of(context)!.calculated_from_sizes : null,
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

  Widget _buildSizesCard() {
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
          _buildCardTitle(Icons.straighten_rounded, AppLocalizations.of(context)!.stock_distribution),
          const SizedBox(height: 15),
          _buildEnhancedSizesTable(),
        ],
      ),
    );
  }

  Widget _buildEnhancedSizesTable() {
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
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.size,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.quantity,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          ..._currentSizes.map(
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
          label: Text(
            AppLocalizations.of(context)!.edit_size_details,
            style: const TextStyle(color: Colors.white),
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

            if (price == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.please_enter_valid_data),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
              return;
            }

            // Calculate total stock from current sizes or use manual entry
            int totalStock = widget.product.stockQuantity;
            if (_currentSizes.isNotEmpty) {
              totalStock = _currentSizes.fold(
                0,
                (sum, item) => sum + item.quantity,
              );
            } else {
              final int? stock = int.tryParse(_stockController.text);
              if (stock == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.please_enter_valid_data),
                    backgroundColor: Colors.orangeAccent,
                  ),
                );
                return;
              }
              totalStock = stock;
            }

            final updatedProduct = ProductModel(
              id: widget.product.id,
              name: _nameController.text,
              sellingPrice: price,
              costPrice: widget.product.costPrice,
              stockQuantity: totalStock,
              category: widget.product.category,
              imageUrl: widget.product.imageUrl,
              sizes: _currentSizes.isNotEmpty ? _currentSizes : null,
            );

            context.read<ProductsBloc>().add(
              UpdateProductEvent(updatedProduct),
            );

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.changes_saved_successfully),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );

            Navigator.pop(context);
          },
          child: Text(
            AppLocalizations.of(context)!.save_changes,
            style: const TextStyle(
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
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context)!.delete_product_confirm_title),
              ],
            ),
            content: Text(
              AppLocalizations.of(context)!.delete_product_confirm_body,
              style: const TextStyle(color: Colors.blueGrey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: const TextStyle(color: Colors.grey),
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
                child: Text(
                  AppLocalizations.of(context)!.delete_permanently,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showEditSizesDialog() {
    List<ProductSize> tempSizes = List.from(_currentSizes);

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
                  children: [
                    const Icon(Icons.straighten, color: Color(0xFF1E3A8A)),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.edit_sizes,
                      style: const TextStyle(color: Color(0xFF1E3A8A)),
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
                                        hintText: AppLocalizations.of(context)!.size,
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
                                        hintText: AppLocalizations.of(context)!.quantity,
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
                        label: Text(AppLocalizations.of(context)!.add_new_size),
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
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: const TextStyle(color: Colors.grey),
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
                      // Filter out empty sizes and update the state
                      final validSizes =
                          tempSizes
                              .where((s) => s.size.isNotEmpty && s.quantity > 0)
                              .toList();

                      if (validSizes.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.please_add_at_least_one_size,
                            ),
                            backgroundColor: Colors.orangeAccent,
                          ),
                        );
                        return;
                      }

                      int newTotalStock = validSizes.fold(
                        0,
                        (sum, item) => sum + item.quantity,
                      );

                      // Update parent state with new sizes
                      setState(() {
                        _currentSizes = validSizes;
                        _stockController.text = newTotalStock.toString();
                      });

                      Navigator.pop(context);

                      // Show confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.sizes_updated_successfully),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context)!.save_changes,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }
}
