import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invento/features/orders/domain/entities/order_entity.dart';
import 'package:invento/features/orders/domain/entities/product_entity.dart';
import 'package:invento/features/home/presentation/pages/order_invoice_screen.dart';
import 'package:invento/features/products/data/models/order_model.dart';

import 'package:invento/features/products/presentation/bloc/orders_bloc.dart';
import 'package:invento/features/products/presentation/bloc/orders_event.dart';
import 'package:invento/features/products/presentation/bloc/products_bloc.dart';
import 'package:invento/features/products/presentation/bloc/products_event.dart';
import 'package:invento/features/products/presentation/bloc/products_state.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key, this.scrollController});
  final ScrollController? scrollController;

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  ProductEntity? _selectedProduct;
  String _customerName = '';
  String _customerPhone = '';
  String _customerAddress = '';
  String _selectedCity = 'القاهرة';
  double _deliveryFee = 0.0;
  int _quantity = 1;
  OrderSource _selectedSource = OrderSource.facebook;
  String? _selectedSize;

  Map<String, double> _shippingFees = {};
  bool _isLoadingFees = true;

  @override
  void initState() {
    super.initState();
    context.read<ProductsBloc>().add(LoadProductsEvent());
    _loadShippingFees();
  }

  Future<void> _loadShippingFees() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('merchants')
              .doc(uid)
              .get();

      if (doc.exists && doc.data()!['cityFees'] != null) {
        final Map<String, dynamic> feesData = doc.data()!['cityFees'];
        setState(() {
          _shippingFees = feesData.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );

          if (_shippingFees.isNotEmpty) {
            _selectedCity = _shippingFees.keys.first;
            _deliveryFee = _shippingFees[_selectedCity]!;
          }
          _isLoadingFees = false;
        });
      } else {
        setState(() {
          _shippingFees = {
            'القاهرة': 50.0,
            'الجيزة': 50.0,
            'المنصوره': 70.0,
            'الاسكندريه': 80.0,
            'طنطا': 80.0,
          };
          _selectedCity = 'القاهرة';
          _deliveryFee = 50.0;
          _isLoadingFees = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading fees: $e");
      setState(() => _isLoadingFees = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar:
          widget.scrollController == null
              ? AppBar(
                title: const Text(
                  "إنشاء أوردر جديد",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
              )
              : null,
      body: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) {
          final products =
              state is ProductsLoaded ? state.products : <ProductEntity>[];
          if (_isLoadingFees) {
            const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Product Details Card ---
                  _buildSectionCard(
                    title: "تفاصيل المنتج",
                    icon: Icons.inventory_2_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<ProductEntity>(
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          menuMaxHeight: 400,
                          borderRadius: BorderRadius.circular(20),
                          decoration: InputDecoration(
                            labelText: "اختر المنتج من المخزن",
                            labelStyle: const TextStyle(color: Colors.blueGrey),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18.0,
                              horizontal: 16.0,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          items:
                              products.map((p) {
                                bool isOutOfStock = p.stockQuantity <= 0;
                                return DropdownMenuItem<ProductEntity>(
                                  value: p,
                                  enabled: !isOutOfStock,
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.6,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            "${p.name} (${p.sellingPrice} ج.م)",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              decoration:
                                                  isOutOfStock
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                              color:
                                                  isOutOfStock
                                                      ? Colors.grey
                                                      : Colors.black,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        isOutOfStock
                                            ? const Text(
                                              "نفذت",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                            : Text(
                                              "متاح: ${p.stockQuantity}",
                                              style: TextStyle(
                                                color:
                                                    p.stockQuantity < 5
                                                        ? Colors.orange
                                                        : Colors.green,
                                                fontSize: 10,
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged:
                              (value) => setState(() {
                                _selectedProduct = value;
                                _selectedSize = null;
                                _quantity = 1;
                              }),
                          validator:
                              (value) =>
                                  value == null ? "برجاء اختيار منتج" : null,
                        ),
                        const SizedBox(height: 15),

                        // 2. اختيار المقاس (يظهر فقط إذا كان المنتج يدعم المقاسات)
                        if (_selectedProduct != null &&
                            _selectedProduct!.sizes != null &&
                            _selectedProduct!.sizes!.isNotEmpty) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedSize,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            decoration: InputDecoration(
                              labelText: "المقاس المتاح",
                              labelStyle: const TextStyle(
                                color: Colors.blueGrey,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 18.0,
                                horizontal: 16.0,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2563EB),
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.straighten,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            items:
                                _selectedProduct!.sizes!.map((s) {
                                  bool isSizeEmpty = s.quantity <= 0;
                                  return DropdownMenuItem<String>(
                                    value: s.size,
                                    enabled: !isSizeEmpty,
                                    child: Text(
                                      "${s.size} ${isSizeEmpty ? '(نفذ)' : '(متاح: ${s.quantity})'}",
                                    ),
                                  );
                                }).toList(),
                            onChanged:
                                (val) => setState(() {
                                  _selectedSize = val;
                                  _quantity = 1;
                                }),
                            validator:
                                (val) =>
                                    val == null ? "برجاء اختيار المقاس" : null,
                          ),
                          const SizedBox(height: 15),
                        ],

                        // 3. قسم الكمية
                        _buildQuantitySection(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- Customer Info Card ---
                  _buildSectionCard(
                    title: "بيانات العميل والشحن",
                    icon: Icons.local_shipping_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(
                          "اسم العميل",
                          (val) => _customerName = val,
                        ),
                        _buildTextField(
                          "رقم الهاتف",
                          (val) => _customerPhone = val,
                          isPhone: true,
                        ),
                        _buildTextField(
                          "عنوان الشحن بالتفصيل",
                          (val) => _customerAddress = val,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCity,
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                decoration: InputDecoration(
                                  labelText: "المحافظة",
                                  labelStyle: const TextStyle(
                                    color: Colors.blueGrey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18.0,
                                    horizontal: 16.0,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF2563EB),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                items:
                                    _shippingFees.keys
                                        .map(
                                          (city) => DropdownMenuItem(
                                            value: city,
                                            child: Text(city),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (val) => setState(() {
                                      _selectedCity = val!;
                                      _deliveryFee = _shippingFees[val]!;
                                    }),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                key: ValueKey(_deliveryFee),
                                initialValue: _deliveryFee.toString(),
                                readOnly: true,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                                decoration: InputDecoration(
                                  labelText: "مصاريف الشحن",
                                  suffixText: "ج.م",
                                  filled: true,
                                  fillColor: Colors.blue.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- Source Card ---
                  _buildSectionCard(
                    title: "مصدر الطلب",
                    icon: Icons.share_rounded,
                    child: DropdownButtonFormField<OrderSource>(
                      value: _selectedSource,
                      decoration: InputDecoration(
                        labelText: "مصدر الطلب",
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.public,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      items:
                          OrderSource.values
                              .map(
                                (src) => DropdownMenuItem(
                                  value: src,
                                  child: Text(src.name.toUpperCase()),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (val) => setState(() => _selectedSource = val!),
                    ),
                  ), // Close _buildSectionCard
                  // --- Submit Button ---
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF1E3A8A,
                          ).withValues(alpha: 0.25),
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
                      onPressed: _submitOrder,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "تأكيد الطلب وتحديث المخزن",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    Function(String) onChange, {
    bool isPhone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        onChanged: onChange,
        validator:
            (val) => val == null || val.isEmpty ? "هذا الحقل مطلوب" : null,
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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

  void _submitOrder() {
    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      // 1. التحقق من اختيار المقاس (إذا كان المنتج يحتوي على مقاسات)
      if (_selectedProduct!.sizes != null &&
          _selectedProduct!.sizes!.isNotEmpty &&
          _selectedSize == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("برجاء اختيار المقاس المطلوب أولاً"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 2. حساب الإجماليات
      double productsTotal = _selectedProduct!.sellingPrice * _quantity;
      double finalTotal = productsTotal + _deliveryFee;

      final order = OrderModel(
        id: "INV-${DateTime.now().millisecondsSinceEpoch}",
        userId: FirebaseAuth.instance.currentUser!.uid,
        customerName: _customerName,
        customerPhone: _customerPhone,
        shippingAddress: _customerAddress,
        city: _selectedCity,
        deliveryFee: _deliveryFee,
        totalAmount: finalTotal,
        status: OrderStatus.pending,
        source: _selectedSource,
        createdAt: DateTime.now(),
        items: [
          OrderItemModel(
            productId: _selectedProduct!.id!,
            productName: _selectedProduct!.name,
            quantity: _quantity,
            priceAtTimeOfOrder: _selectedProduct!.sellingPrice,
            costPriceAtTimeOfOrder: _selectedProduct!.costPrice,
            selectedSize: _selectedSize,
          ),
        ],
      );

      context.read<OrdersBloc>().add(CreateOrderEvent(order));

      _showSuccessDialog(order);
    }
  }

  void _showSuccessDialog(OrderEntity order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
                content: const Text(
                  "تم تسجيل الأوردر بنجاح!",
                  textAlign: TextAlign.center,
                ),
                actions: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          // pop the dialog
                          Navigator.pop(context);
                          // go to the invoice screen replacing the current order creator
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => OrderInvoiceScreen(order: order),
                            ),
                          );
                        },
                        child: const Text(
                          "عرض بوليصة الشحن",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // قفل الـ Dialog
                          Navigator.pop(context); // العودة للـ Dashboard
                        },
                        child: const Center(
                          child: Text(
                            "العودة للرئيسية",
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildQuantitySection() {
    int maxAvailable = 0;
    if (_selectedProduct != null) {
      if (_selectedSize != null) {
        maxAvailable =
            _selectedProduct!.sizes!
                .firstWhere((s) => s.size == _selectedSize)
                .quantity;
      } else {
        maxAvailable = _selectedProduct!.stockQuantity;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "الكمية المطلوبة",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepButton(
                icon: Icons.remove,
                color: Colors.red,
                onPressed: () {
                  if (_quantity > 1) setState(() => _quantity--);
                },
              ),
              Column(
                children: [
                  Text(
                    "$_quantity",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedProduct != null)
                    Text(
                      "من أصل $maxAvailable",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              _buildStepButton(
                icon: Icons.add,
                color: Colors.green,
                onPressed: () {
                  if (_selectedProduct == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("برجاء اختيار منتج أولاً")),
                    );
                  } else if (_quantity < maxAvailable) {
                    setState(() => _quantity++);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
