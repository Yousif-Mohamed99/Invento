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
  String _selectedCategory = 'ملابس';
  final List<String> _categories = [
    'ملابس',
    'أحذية',
    'عطور',
    'إكسسوارات',
    'أدوات منزلية',
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
      appBar: AppBar(title: const Text("إضافة منتج جديد"), centerTitle: true),
      body: BlocListener<ProductsBloc, ProductsState>(
        listener: (context, state) {
          if (state is ProductsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("تم إضافة المنتج بنجاح!"),
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
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePicker(),
                const SizedBox(height: 20),

                // --- اسم المنتج ---
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "اسم المنتج",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? "مطلوب" : null,
                ),
                const SizedBox(height: 15),

                // --- الفئات ---
                DropdownButtonFormField(
                  value: _selectedCategory,
                  items:
                      _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged:
                      (val) =>
                          setState(() => _selectedCategory = val as String),
                  decoration: const InputDecoration(
                    labelText: "فئة المنتج",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // --- إدارة المقاسات ---
                _buildSizeManager(),
                const SizedBox(height: 20),

                // --- الأسعار ---
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "سعر البيع",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? "مطلوب" : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "التكلفة",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? "مطلوب" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  enabled: _selectedSizes.isEmpty,
                  decoration: InputDecoration(
                    labelText:
                        _selectedSizes.isEmpty
                            ? "الكمية الكلية"
                            : "الكمية (محسوبة من المقاسات)",
                    border: const OutlineInputBorder(),
                    filled: _selectedSizes.isNotEmpty,
                  ),
                  validator:
                      (v) =>
                          (_selectedSizes.isEmpty && v!.isEmpty)
                              ? "مطلوب"
                              : null,
                ),
                const SizedBox(height: 30),

                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child:
            _selectedImage == null
                ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                    Text("صورة المنتج"),
                  ],
                )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
      ),
    );
  }

  Widget _buildSizeManager() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "المقاسات المتاحة",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _sizeNameController,
                decoration: const InputDecoration(
                  labelText: "المقاس (L, 42...)",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _sizeQtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "الكمية",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              onPressed: _addSize,
              icon: const Icon(Icons.add_box, color: Colors.blue, size: 40),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children:
              _selectedSizes
                  .map(
                    (s) => Chip(
                      label: Text("${s.size} : ${s.quantity}"),
                      onDeleted: () => setState(() => _selectedSizes.remove(s)),
                      backgroundColor: Colors.blue[50],
                      deleteIconColor: Colors.red,
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed:
              state is ProductsLoading
                  ? null
                  : () {
                    if (_formKey.currentState!.validate() &&
                        _selectedImage != null) {
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
                        category: _selectedCategory,
                        imageUrl: '',
                        sizes: _selectedSizes,
                      );

                      context.read<ProductsBloc>().add(
                        AddProductEvent(product, _selectedImage!),
                      );
                    } else if (_selectedImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("من فضلك اختر صورة")),
                      );
                    }
                  },
          child:
              state is ProductsLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                    "حفظ المنتج في المخزن",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
        );
      },
    );
  }
}
