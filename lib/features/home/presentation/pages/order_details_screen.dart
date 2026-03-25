import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:invento/core/injection_container.dart';
import 'package:invento/features/orders/domain/entities/order_entity.dart';
import 'package:invento/features/orders/domain/repositories/orders_repository.dart';
import 'package:invento/features/products/presentation/bloc/orders_bloc.dart';
import 'package:invento/features/products/presentation/bloc/orders_event.dart';
import 'package:invento/features/products/presentation/bloc/products_bloc.dart';
import 'package:invento/features/products/presentation/bloc/products_event.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            children: [
              TextSpan(
                text: "${AppLocalizations.of(context)!.order_details_for} ",
                style: const TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: "#${orderId.toUpperCase().substring(0, 7)}",
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<OrderEntity>(
        future: GetIt.I<OrdersRepository>().getOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text(AppLocalizations.of(context)!.inventory_empty));

          final order = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(context, order.status),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.customer_details,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                _buildCustomerInfoCard(context, order),
                const SizedBox(height: 16),

                Text(
                  AppLocalizations.of(context)!.products,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                _buildOrderItemsList(context, order.items),
                const SizedBox(height: 16),

                _buildFinancialSummary(context, order),

                const SizedBox(height: 32),

                _buildActionButtons(context, order),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _buildStatusCard(BuildContext context, OrderStatus status) {
  Color statusColor =
      status == OrderStatus.pending ? Colors.orange.shade700 : Colors.green;
  Color bgColor =
      status == OrderStatus.pending
          ? Colors.orange.shade50
          : Colors.green.shade50;
  String statusText =
      status == OrderStatus.pending ? AppLocalizations.of(context)!.pending : AppLocalizations.of(context)!.shipped;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context)!.order_status,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1E3A8A),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                status == OrderStatus.pending
                    ? Icons.pending_actions_rounded
                    : Icons.check_circle_rounded,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildCustomerInfoCard(BuildContext context, OrderEntity order) {
  return Container(
    padding: const EdgeInsets.all(16),
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
    child: Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Color(0xFF2563EB)),
          ),
          title: Text(
            order.customerName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          subtitle: Text(order.customerPhone),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  FontAwesomeIcons.phone,
                  color: Colors.green,
                  size: 20,
                ),
                onPressed:
                    () => launchUrl(Uri.parse("tel:${order.customerPhone}")),
              ),
              IconButton(
                icon: const Icon(
                  FontAwesomeIcons.whatsapp,
                  color: Colors.green,
                ),
                onPressed:
                    () => launchUrl(
                      Uri.parse("https://wa.me/2${order.customerPhone}"),
                    ),
              ),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Colors.redAccent,
            ),
          ),
          title: Text(
            AppLocalizations.of(context)!.delivery_address,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("${order.city} - ${order.shippingAddress}"),
        ),
      ],
    ),
  );
}

Widget _buildFinancialSummary(BuildContext context, OrderEntity order) {
  // Calculate total products before shipping
  final double subTotal = order.totalAmount - order.deliveryFee;

  return Container(
    padding: const EdgeInsets.all(16),
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
    child: Column(
      children: [
        _buildPriceRow(context, AppLocalizations.of(context)!.items_total, "$subTotal ${AppLocalizations.of(context)!.egp}"),
        _buildPriceRow(context, AppLocalizations.of(context)!.delivery_fee, "${order.deliveryFee} ${AppLocalizations.of(context)!.egp}"),
        const Divider(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildPriceRow(
            context,
            AppLocalizations.of(context)!.grand_total,
            "${order.totalAmount} ${AppLocalizations.of(context)!.egp}",
            isTotal: true,
          ),
        ),
      ],
    ),
  );
}

Widget _buildPriceRow(BuildContext context, String label, String value, {bool isTotal = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.blue : Colors.black,
          ),
        ),
      ],
    ),
  );
}

Widget _buildActionButtons(BuildContext context, OrderEntity order) {
  // If order is already cancelled, don't show control buttons
  if (order.status == OrderStatus.cancelled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.order_cancelled,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  return Column(
    children: [
      // Update button for "Shipped" (shows only if pending)
      if (order.status == OrderStatus.pending)
        Container(
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
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _showUpdateStatusDialog(context, order.id!),
            icon: const Icon(Icons.local_shipping, color: Colors.white),
            label: Text(
              AppLocalizations.of(context)!.update_to_shipped,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

      const SizedBox(height: 16),

      // Cancel order button (shows in all cases except cancelled or delivered)
      SizedBox(
        width: double.infinity,
        height: 55,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            foregroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () => _showCancelDialog(context, order), // Cancel function
          icon: const Icon(Icons.cancel_outlined),
          label: Text(
            AppLocalizations.of(context)!.cancel_order,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ],
  );
}

void _showCancelDialog(BuildContext context, OrderEntity order) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.confirm_cancellation,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)!.cancel_order_confirm_body,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.undo, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final ordersBloc = context.read<OrdersBloc>();
                final productsBloc = context.read<ProductsBloc>();

                await sl<OrdersRepository>().cancelOrder(order);

                // Refresh Blocs to update UI everywhere
                ordersBloc.add(LoadOrdersEvent());
                productsBloc.add(LoadProductsEvent());

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.order_cancelled_inventory_restored),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: Text(
                AppLocalizations.of(context)!.cancel_order_now,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
  );
}

void _showUpdateStatusDialog(BuildContext context, String orderId) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.blueAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.update_status,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)!.confirm_shipped_status_body,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final ordersBloc = context.read<OrdersBloc>();
                final productsBloc = context.read<ProductsBloc>();

                await sl<OrdersRepository>().updateOrderStatus(
                  orderId: orderId,
                  newStatus: OrderStatus.shipped,
                );

                // Refresh Blocs to update Dashboard and Stats
                ordersBloc.add(LoadOrdersEvent());
                productsBloc.add(LoadProductsEvent());

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.order_updated_successfully),
                      backgroundColor: const Color(0xFF1E3A8A),
                    ),
                  );
                }
              },
              child: Text(
                AppLocalizations.of(context)!.confirm,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
  );
}

Widget _buildOrderItemsList(BuildContext context, List<OrderItem> items) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
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
    child: ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder:
          (context, index) =>
              Divider(indent: 16, endIndent: 16, color: Colors.grey.shade100),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.blueGrey,
            ),
          ),
          title: Text(
            item.productName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          subtitle: Text("${AppLocalizations.of(context)!.quantity}: ${item.quantity}"),
          trailing: Text(
            "${item.priceAtTimeOfOrder * item.quantity} ${AppLocalizations.of(context)!.egp}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
              fontSize: 15,
            ),
          ),
        );
      },
    ),
  );
}
