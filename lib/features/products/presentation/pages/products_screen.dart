import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invento/features/products/presentation/pages/product_details_screen.dart';
import '../bloc/products_bloc.dart';
import '../bloc/products_event.dart';
import '../bloc/products_state.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();

    context.read<ProductsBloc>().add(LoadProductsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("مخزن المنتجات"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) {
          if (state is ProductsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProductsLoaded) {
            if (state.products.isEmpty) {
              return _buildEmptyState();
            }

            // Extract unique categories from products
            final categories =
                state.products
                    .where((p) => p.category != null && p.category!.isNotEmpty)
                    .map((p) => p.category!)
                    .toSet()
                    .toList();

            // Filter products by selected category
            final filteredProducts =
                _selectedCategory == null
                    ? state.products
                    : state.products
                        .where((p) => p.category == _selectedCategory)
                        .toList();

            return Column(
              children: [
                // Category filter chips
                if (categories.isNotEmpty) _buildCategoryFilter(categories),
                // Product list
                Expanded(
                  child:
                      filteredProducts.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 60,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "لا توجد منتجات في هذه الفئة",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return _buildProductCard(product);
                            },
                          ),
                ),
              ],
            );
          } else if (state is ProductsError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text("ابدأ بإضافة منتجاتك"));
        },
      ),
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // "All" chip
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: const Text("الكل"),
                selected: _selectedCategory == null,
                onSelected: (_) => setState(() => _selectedCategory = null),
                selectedColor: const Color(0xFF2563EB),
                backgroundColor: Colors.grey.shade100,
                labelStyle: TextStyle(
                  color:
                      _selectedCategory == null
                          ? Colors.white
                          : Colors.blueGrey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color:
                        _selectedCategory == null
                            ? const Color(0xFF2563EB)
                            : Colors.grey.shade200,
                  ),
                ),
                showCheckmark: false,
              ),
            ),
            // Category chips
            ...categories.map(
              (cat) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: const Color(0xFF2563EB),
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color:
                        _selectedCategory == cat
                            ? Colors.white
                            : Colors.blueGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color:
                          _selectedCategory == cat
                              ? const Color(0xFF2563EB)
                              : Colors.grey.shade200,
                    ),
                  ),
                  showCheckmark: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => BlocProvider.value(
                      value: context.read<ProductsBloc>(),
                      child: ProductDetailsScreen(product: product),
                    ),
              ),
            );
            if (context.mounted) {
              context.read<ProductsBloc>().add(LoadProductsEvent());
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child:
                      product.imageUrl != null && product.imageUrl.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          )
                          : Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.grey.shade400,
                            size: 36,
                          ),
                ),
                const SizedBox(width: 16),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E3A8A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${product.sellingPrice} ج.م",
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStockBadge(product.stockQuantity),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(int stock) {
    Color color =
        stock > 5
            ? Colors.green
            : (stock > 0 ? Colors.orange.shade700 : Colors.red);
    Color bgColor =
        stock > 5
            ? Colors.green.shade50
            : (stock > 0 ? Colors.orange.shade50 : Colors.red.shade50);
    String label = stock > 0 ? "متوفر: $stock" : "نفد من المخزن";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "لا توجد منتجات حالياً",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
