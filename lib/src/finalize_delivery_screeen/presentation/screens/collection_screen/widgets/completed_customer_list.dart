import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/domain/entity/collection_entity.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

class CompletedCustomerList extends StatelessWidget {
  final List<CollectionEntity> collections;
  final bool isOffline;

  const CompletedCustomerList({
    super.key,
    required this.collections,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOffline) {
      return Column(
        children: [
          _buildOfflineIndicator(),
          const SizedBox(height: 8),
          _buildCustomerList(context),
        ],
      );
    }

    return _buildCustomerList(context);
  }

  Widget _buildCustomerList(BuildContext context) {
    debugPrint('📋 CUSTOMER LIST: Processing ${collections.length} collections');

    // Filter collections that have customer data (completed customers)
    final completedCollections = collections.where((collection) {
      final hasCustomer = collection.customer.target != null;
      debugPrint('🔍 Collection ${collection.id}: has customer = $hasCustomer');
      return hasCustomer;
    }).toList();

    debugPrint('✅ CUSTOMER LIST: Found ${completedCollections.length} completed collections with customers');

    if (completedCollections.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: completedCollections.length,
      itemBuilder: (context, index) {
        final collection = completedCollections[index];
        
        // Get customer data directly from collection entity
        final customer = collection.customer.target;
        final invoices = collection.invoices;
        
        debugPrint('👤 Processing customer for collection ${collection.id}:');
        debugPrint('   - Customer ID: ${customer?.id}');
        debugPrint('   - Customer Name: ${customer?.name}');
        debugPrint('   - Owner Name: ${customer?.ownerName}');
        debugPrint('   - Number of invoices: ${invoices.length}');
        debugPrint('   - Collection Total: ${collection.totalAmount}');
        
        // Log individual invoice details
        for (int i = 0; i < invoices.length; i++) {
          final invoice = invoices[i];
          debugPrint('   - Invoice ${i + 1} (${invoice.refId ?? invoice.name}): ₱${NumberFormat('#,##0.00').format(invoice.totalAmount ?? 0.0)}');
        }
        
        // Extract customer information directly from collection's customer relation
        final customerName = customer?.ownerName ?? customer?.name ?? 'Unknown Customer';
        final storeName = customer?.name ?? customerName;
        
        // Calculate total amount from all invoices
        double totalAmount = 0.0;
        if (invoices.isNotEmpty) {
          totalAmount = invoices.fold<double>(0.0, (sum, invoice) => sum + (invoice.totalAmount ?? 0.0));
        }
        
        // Fallback to collection totalAmount if invoices don't have amounts
        if (totalAmount == 0.0 && collection.totalAmount != null) {
          totalAmount = collection.totalAmount!;
          debugPrint('   🔄 Using collection totalAmount as fallback: ₱${NumberFormat('#,##0.00').format(totalAmount)}');
        }
        
        debugPrint('📊 Final display data:');
        debugPrint('   - Store Name: $storeName');
        debugPrint('   - Customer Name: $customerName');
        debugPrint('   - Total Amount: ₱${NumberFormat('#,##0.00').format(totalAmount)}');
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: CommonListTiles(
            onTap: () {
              debugPrint('🔄 Navigating to collection details: ${collection.id}');
              context.push(
                '/collection-details/${collection.id}',
                extra: {
                  'collection': collection,
                  'customer': customer,
                  'invoices': invoices.toList(),
                  'isOffline': isOffline,
                },
              );
            },
            title: storeName,
            subtitle: '${invoices.length} ${invoices.length == 1 ? 'Invoice' : 'Invoices'} • ₱${NumberFormat('#,##0.00').format(totalAmount)}',
            leading: CircleAvatar(
              backgroundColor: isOffline 
                  ? Colors.orange.withOpacity(0.1)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.store,
                color: isOffline 
                    ? Colors.orange
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOffline)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.offline_bolt,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ),
                // Add customer status indicator
                if (customer?.ownerName != null && customer!.ownerName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                  ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isOffline 
                  ? BorderSide(color: Colors.orange.withOpacity(0.3))
                  : BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: isOffline 
                ? Colors.orange.withOpacity(0.05)
                : Theme.of(context).colorScheme.surface,
          ),
        );
      },
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_bolt, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Text(
            'Showing offline data',
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Completed Customers',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed deliveries will appear here',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
