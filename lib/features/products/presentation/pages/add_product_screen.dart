import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:invento/features/orders/domain/entities/product_entity.dart';
import 'package:invento/features/products/data/models/product_model.dart';
import 'package:invento/features/products/presentation/bloc/products_bloc.dart';
import 'package:invento/features/products/presentation/bloc/products_event.dart';
import 'package:invento/features/products/presentation/bloc/products_state.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();

  File? _selectedImage;
  String _selectedCategory = 'Clothes';
  bool _isCustomCategory = false;
  final _customCategoryController = TextEditingController();
  final List<String> _defaultCategories = [
    'Clothes',
    'Shoes',
    'Perfumes',
    'Accessories',
    'Home Tools',
  ];

  final _sizeNameController = TextEditingController();
  final _sizeQtyController = TextEditingController();

  final List<ProductSize> _selectedSizes = [];

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  void _addSize() {
    if (_sizeNameController.text.isNotEmpty &&
        _sizeQtyController.text.isNotEmpty) {
      setState(() {
        _selectedSizes.add(
          ProductSize(
            size: _sizeNameController.text.trim().toUpperCase(),
            quantity: int.parse(_sizeQtyController.text),
          ),
        );
        _sizeNameController.clear();
        _sizeQtyController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Add New Product",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
      ),
      body: BlocListener<ProductsBloc, ProductsState>(
        listener: (context, state) {
          if (state is ProductsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Product added successfully!"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is ProductsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Image Section ---
                _buildSectionCard(
                  title: "Product Image",
                  icon: Icons.image_outlined,
                  child: _buildImagePicker(),
                ),
                const SizedBox(height: 16),

                // --- Product Info Section ---
                _buildSectionCard(
                  title: "Product Data",
                  icon: Icons.inventory_2_rounded,
                  child: Column(
                    children: [
                      _buildTextFormField(
                        controller: _nameController,
                        label: "Product Name",
                        icon: Icons.edit_note_rounded,
                      ),
                      const SizedBox(height: 15),
                      _buildCategorySelector(),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _priceController,
                              label: "Selling Price",
                              icon: Icons.payments_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextFormField(
                              controller: _costController,
                              label: "Cost",
                              icon: Icons.money_off_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildTextFormField(
                        controller: _stockController,
                        label:
                            _selectedSizes.isEmpty
                                ? "Total Quantity"
                                : "Quantity (calculated from sizes)",
                        icon: Icons.inventory_outlined,
                        keyboardType: TextInputType.number,
                        enabled: _selectedSizes.isEmpty,
                        validator:
                            (v) =>
                                (_selectedSizes.isEmpty && v!.isEmpty)
                                    ? "Required"
                                    : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- Sizes Section ---
                _buildSectionCard(
                  title: "Available Sizes",
                  icon: Icons.straighten_rounded,
                  child: _buildSizeManager(),
                ),
                const SizedBox(height: 24),

                // --- Save Button ---
                _buildSaveButton(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Section Card (matches create_order_screen pattern) ──────────────
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1E3A8A), size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ─── Shared InputDecoration ─────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.blueGrey),
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 22),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 18.0,
        horizontal: 16.0,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  // ─── Styled TextFormField ───────────────────────────────────────────
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: enabled ? Colors.black87 : Colors.blueGrey,
      ),
      decoration: _inputDecoration(label: label, icon: icon).copyWith(
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
      ),
      validator: validator ?? (v) => v!.isEmpty ? "This field is required" : null,
    );
  }

  // ─── Image Picker ───────────────────────────────────────────────────
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child:
            _selectedImage == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 40,
                      color: const Color(0xFF2563EB).withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Tap to select product image",
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
      ),
    );
  }

  // ─── Size Manager ──────────────────────────────────────────────────
  Widget _buildSizeManager() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _sizeNameController,
                decoration: _inputDecoration(
                  label: "Size (L, 42...)",
                  icon: Icons.straighten,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _sizeQtyController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  label: "Quantity",
                  icon: Icons.numbers,
                ).copyWith(prefixIcon: null),
              ),
            ),
            const SizedBox(width: 4),
            Material(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _addSize,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.add_rounded,
                    color: Color(0xFF2563EB),
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _selectedSizes
                  .map(
                    (s) => Chip(
                      label: Text(
                        "${s.size} : ${s.quantity}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      onDeleted: () => setState(() => _selectedSizes.remove(s)),
                      backgroundColor: const Color(
                        0xFF2563EB,
                      ).withValues(alpha: 0.08),
                      deleteIconColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  // ─── Category Selector (dropdown + custom input) ───────────────────
  Widget _buildCategorySelector() {
    // Combine default categories with "add new" option
    const String addNewKey = '__add_new__';

    if (_isCustomCategory) {
      // Show text field for custom category
      return Row(
        children: [
          Expanded(
            child: _buildTextFormField(
              controller: _customCategoryController,
              label: "Type new category name",
              icon: Icons.category_outlined,
              validator: (v) => v!.isEmpty ? "Enter category name" : null,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isCustomCategory = false;
                  _customCategoryController.clear();
                  _selectedCategory = _defaultCategories.first;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.redAccent,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(20),
      items: [
        ..._defaultCategories.map(
          (c) => DropdownMenuItem(value: c, child: Text(c)),
        ),
        const DropdownMenuItem(
          value: addNewKey,
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "Add New Category",
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      onChanged: (val) {
        if (val == addNewKey) {
          setState(() => _isCustomCategory = true);
        } else {
          setState(() => _selectedCategory = val!);
        }
      },
      decoration: _inputDecoration(
        label: "Product Category",
        icon: Icons.category_outlined,
      ),
    );
  }

  // ─── Save Button (gradient, matches other screens) ─────────────────
  Widget _buildSaveButton() {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        if (state is ProductsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              if (_formKey.currentState!.validate() && _selectedImage != null) {
                int totalStock =
                    _selectedSizes.isNotEmpty
                        ? _selectedSizes.fold(
                          0,
                          (sum, item) => sum + item.quantity,
                        )
                        : int.parse(_stockController.text);

                final product = ProductModel(
                  name: _nameController.text,
                  costPrice: double.parse(_costController.text),
                  sellingPrice: double.parse(_priceController.text),
                  stockQuantity: totalStock,
                  category:
                      _isCustomCategory
                          ? _customCategoryController.text.trim()
                          : _selectedCategory,
                  imageUrl: '',
                  sizes: _selectedSizes,
                );

                context.read<ProductsBloc>().add(
                  AddProductEvent(product, _selectedImage!),
                );
              } else if (_selectedImage == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select an image")),
                );
              }
            },
            child: const Text(
              "Save Product to Stock",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
