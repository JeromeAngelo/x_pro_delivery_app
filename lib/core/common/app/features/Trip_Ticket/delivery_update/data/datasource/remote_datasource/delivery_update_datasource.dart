import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'dart:typed_data' show Uint8List;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:x_pro_delivery_app/core/services/location_services.dart';

import '../../models/delivery_update_model.dart';

abstract class DeliveryUpdateDatasource {
  Future<List<DeliveryUpdateModel>> getDeliveryStatusChoices(String customerId);
  Future<void> updateDeliveryStatus(String customerId, String statusId);
  Future<void> completeDelivery(DeliveryDataEntity deliveryData);
  Future<DataMap> checkEndDeliverStatus(String tripId);
  Future<void> initializePendingStatus(List<String> customerIds);
  Future<Map<String, List<DeliveryUpdateModel>>> getBulkDeliveryStatusChoices(
    List<String> customerIds,
  );
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    String statusId,
  );
  Future<void> createDeliveryStatus(
    String customerId, {
    required String title,
    required String subtitle,
    required DateTime time,
    required bool isAssigned,
    required String image,
  });
  Future<void> updateQueueRemarks(String statusId, String remarks, String image);
  Future<void> pinArrivedLocation(String deliveryId);
}

class DeliveryUpdateDatasourceImpl implements DeliveryUpdateDatasource {
  const DeliveryUpdateDatasourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;
@override
Future<void> updateQueueRemarks(
  String statusId,
  String remarks,
  String image,
) async {
  try {
    debugPrint('📝 Updating queue remarks for status: $statusId');
    final files = <MultipartFile>[];

    // 🔽 Process image if provided
    if (image.isNotEmpty) {
      try {
        final imageFile = File(image);
        if (await imageFile.exists()) {
          debugPrint('📸 Processing status update image...');

          final compressedImageBytes = await _compressImageToSmallSize(image);
          if (compressedImageBytes != null) {
            files.add(
              MultipartFile.fromBytes(
                'image',
                compressedImageBytes,
                filename: 'status_update_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
              ),
            );
            debugPrint(
              '✅ Added compressed image (${compressedImageBytes.length} bytes)',
            );
          } else {
            // fallback to original if compression fails
            final originalBytes = await imageFile.readAsBytes();
            files.add(
              MultipartFile.fromBytes(
                'image',
                originalBytes,
                filename: 'status_update_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
              ),
            );
            debugPrint(
              '⚠️ Using original image (compression failed): ${originalBytes.length} bytes',
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error processing image: $e');
      }
    }
  
    // 🔽 Perform update call to PocketBase (deliveryUpdate collection)
    await _pocketBaseClient.collection('deliveryUpdate').update(
      statusId,
      body: {
        'remarks': remarks,
      },
      files: files,
    );

    debugPrint('✅ Queue remarks successfully updated for status $statusId');
  } catch (e) {
    debugPrint('❌ Failed to update queue remarks: $e');
    throw ServerException(message: e.toString(), statusCode: '404');
  }
}


  @override
  Future<List<DeliveryUpdateModel>> getDeliveryStatusChoices(
    String customerId,
  ) async {
    try {
      debugPrint(
        '🚚 Fetching delivery status choices for customer: $customerId',
      );

      final customerRecord = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(customerId, expand: 'deliveryUpdates');

      final deliveryUpdates = customerRecord.expand['deliveryUpdates'] as List?;
      final latestStatus =
          deliveryUpdates?.isNotEmpty == true
              ? deliveryUpdates!.last.data['title'].toString().toLowerCase()
              : '';

      debugPrint('📍 Latest status for customer $customerId: $latestStatus');

      final allStatuses =
          await _pocketBaseClient
              .collection('deliveryStatusChoices')
              .getFullList();

      // Log available status choices
      for (var status in allStatuses) {
        debugPrint(
          '🏷️ Available Status - ID: ${status.id}, Title: ${status.data['title']}',
        );
      }

      // Handle In Transit status
      if (latestStatus == 'in transit') {
        final allowedTitles = ['arrived', 'mark as undelivered'];
        return _filterStatusChoices(allStatuses, allowedTitles);
      }
      if (latestStatus == 'waiting for customer') {
        final allowedTitles = ['unloading', 'mark as undelivered', 'invoices in queue'];
        return _filterStatusChoices(allStatuses, allowedTitles);
      }

       if (latestStatus == 'invoices in queue') {
        final allowedTitles = ['unloading', 'mark as undelivered'];
        return _filterStatusChoices(allStatuses, allowedTitles);
      }

      // Handle Waiting for customers

      // Handle Unloading
      if (latestStatus == 'unloading') {
        final allowedTitles = ['mark as received'];
        return _filterStatusChoices(allStatuses, allowedTitles);
      }

      if (latestStatus == 'mark as received') {
        final allowedTitles = ['end delivery'];
        return _filterStatusChoices(allStatuses, allowedTitles);
      }

      // Handle Arrived status
      if (latestStatus == 'arrived') {
        final allowedTitles = [
          'unloading',
          'mark as undelivered',
          'waiting for customer',
          'invoices in queue'
        ];
        return _filterStatusChoices(allStatuses, allowedTitles);
      }

      if (latestStatus == 'mark as undelivered') {
        return [];
      }

      if (latestStatus == 'end delivery') {
        return [];
      }

      final assignedTitles =
          deliveryUpdates
              ?.map((record) => record.data['title'].toString().toLowerCase())
              .toSet() ??
          {};

      debugPrint('📋 Already assigned titles: $assignedTitles');

      return allStatuses
          .where(
            (status) =>
                !assignedTitles.contains(
                  status.data['title'].toString().toLowerCase(),
                ),
          )
          .map((record) => DeliveryUpdateModel.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching delivery status choices: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch delivery status choices: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  List<DeliveryUpdateModel> _filterStatusChoices(
    List<RecordModel> allStatuses,
    List<String> allowedTitles,
  ) {
    return allStatuses
        .where(
          (status) => allowedTitles.contains(
            status.data['title'].toString().toLowerCase(),
          ),
        )
        .map((record) {
          final statusId = record.id;
          debugPrint(
            '🏷️ Processing status - ID: $statusId, Title: ${record.data['title']}',
          );

          return DeliveryUpdateModel.fromJson({
            'id': statusId, // Explicit ID assignment
            'collectionId': record.collectionId,
            'collectionName': record.collectionName,
            'title': record.data['title'],
            'subtitle': record.data['subtitle'],
          });
        })
        .toList();
  }

  @override
  Future<Map<String, List<DeliveryUpdateModel>>> getBulkDeliveryStatusChoices(
    List<String> customerIds,
  ) async {
    final Map<String, List<DeliveryUpdateModel>> result = {};

    try {
      debugPrint(
        '🚚 Fetching bulk delivery status choices for customers: $customerIds',
      );

      for (final customerId in customerIds) {
        try {
          final customerRecord = await _pocketBaseClient
              .collection('deliveryData')
              .getOne(customerId, expand: 'deliveryUpdates');

          final deliveryUpdates =
              customerRecord.expand['deliveryUpdates'] as List?;
          final latestStatus =
              deliveryUpdates?.isNotEmpty == true
                  ? deliveryUpdates!.last.data['title'].toString().toLowerCase()
                  : '';

          debugPrint(
            '📍 Latest status for customer $customerId: $latestStatus',
          );

          final allStatuses =
              await _pocketBaseClient
                  .collection('deliveryStatusChoices')
                  .getFullList();

          // Handle different states
          List<DeliveryUpdateModel> filteredStatuses = [];
          if (latestStatus == 'in transit') {
            filteredStatuses = _filterStatusChoices(allStatuses, [
              'arrived',
              'mark as undelivered',
            ]);
          } else if (latestStatus == 'waiting for customer') {
            filteredStatuses = _filterStatusChoices(allStatuses, [
              'unloading',
              'invoices in queue',
              'mark as undelivered',
            ]);
          }  else if (latestStatus == 'invoices in queue') {
            filteredStatuses = _filterStatusChoices(allStatuses, [
              'unloading',
              'mark as undelivered',
            ]);
          } else if (latestStatus == 'unloading') {
            filteredStatuses = _filterStatusChoices(allStatuses, [
              'mark as received',
            ]);
          } else if (latestStatus == 'mark as received') {
            filteredStatuses = _filterStatusChoices(allStatuses, [
              'end delivery',
            ]);
          } else if (latestStatus == 'arrived') {
            filteredStatuses = _filterStatusChoices(allStatuses, [
               'unloading',
          'mark as undelivered',
          'waiting for customer',
          'invoices in queue'
            ]);
          } else if (latestStatus == 'mark as undelivered' ||
              latestStatus == 'end delivery') {
            filteredStatuses = [];
          } else {
            // Default logic: remove already assigned
            final assignedTitles =
                deliveryUpdates
                    ?.map(
                      (record) => record.data['title'].toString().toLowerCase(),
                    )
                    .toSet() ??
                {};

            filteredStatuses =
                allStatuses
                    .where(
                      (status) =>
                          !assignedTitles.contains(
                            status.data['title'].toString().toLowerCase(),
                          ),
                    )
                    .map(
                      (record) => DeliveryUpdateModel.fromJson(record.toJson()),
                    )
                    .toList();
          }

          result[customerId] = filteredStatuses;
          debugPrint(
            '✅ Added ${filteredStatuses.length} statuses for $customerId',
          );
        } catch (e) {
          debugPrint('❌ Failed to fetch statuses for $customerId: $e');
          result[customerId] = [];
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error in bulk status fetch: ${e.toString()}');
      throw ServerException(
        message:
            'Failed to fetch bulk delivery status choices: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<void> updateDeliveryStatus(String customerId, String statusId) async {
    try {
      debugPrint(
        '🔄 Processing status update - Customer: $customerId, Status: $statusId',
      );

      // Validate status ID
      if (statusId.isEmpty) {
        debugPrint('⚠️ Invalid status ID provided');
        throw const ServerException(
          message: 'Invalid status ID',
          statusCode: '400',
        );
      }

      // Get the status record
      final statusRecord = await _pocketBaseClient
          .collection('deliveryStatusChoices')
          .getOne(statusId);

      debugPrint('✅ Retrieved status: ${statusRecord.data['title']}');

      // Create delivery update with validated data
      final currentTime = DateTime.now().toIso8601String();
      final deliveryUpdateRecord = await _pocketBaseClient
          .collection('deliveryUpdate')
          .create(
            body: {
              // 'customer': customerId,
              'deliveryData': customerId,
              'status': statusId,
              'title': statusRecord.data['title'],
              'subtitle': statusRecord.data['subtitle'],
              'created': currentTime,
              'time': currentTime,
              'isAssigned': true,
            },
          );

      debugPrint('📝 Created delivery update: ${deliveryUpdateRecord.id}');

      // Update customer record
      await _pocketBaseClient
          .collection('deliveryData')
          .update(
            customerId,
            body: {
              'deliveryUpdates+': [deliveryUpdateRecord.id],
            },
          );


    // 🔔 Create notification entry
    await _pocketBaseClient.collection('notifications').create(
      body: {
        'status': statusId,
        'delivery': customerId,
        'type': 'deliveryUpdate',
        'created': currentTime,
        'isRead': false,
      },
    );

    debugPrint('🔔 Notification created for status update');

      debugPrint('✅ Successfully updated customer status');
    } catch (e) {
      debugPrint('❌ Operation failed: ${e.toString()}');
      throw ServerException(
        message:
            e is ServerException
                ? e.message
                : 'Operation failed: ${e.toString()}',
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }

  @override
  Future<void> bulkUpdateDeliveryStatus(
    List<String> customerIds,
    String statusId,
  ) async {
    try {
      debugPrint(
        '🔄 Processing bulk status update - Customers: $customerIds, Status: $statusId',
      );

      // Validate status ID
      if (statusId.isEmpty) {
        debugPrint('⚠️ Invalid status ID provided');
        throw const ServerException(
          message: 'Invalid status ID',
          statusCode: '400',
        );
      }

      // Get the status record once (reuse for all customers)
      final statusRecord = await _pocketBaseClient
          .collection('deliveryStatusChoices')
          .getOne(statusId);

      final title = statusRecord.data['title'];
      final subtitle = statusRecord.data['subtitle'];

      debugPrint('✅ Retrieved status: $title');

      final currentTime = DateTime.now().toIso8601String();

      // Iterate over all customers
      for (final customerId in customerIds) {
        try {
          debugPrint('➡️ Updating customer: $customerId');

          // Create delivery update record for this customer
          final deliveryUpdateRecord = await _pocketBaseClient
              .collection('deliveryUpdate')
              .create(
                body: {
                  'deliveryData': customerId,
                  'status': statusId,
                  'title': title,
                  'subtitle': subtitle,
                  'created': currentTime,
                  'time': currentTime,
                  'isAssigned': true,
                },
              );

          debugPrint(
            '📝 Created delivery update: ${deliveryUpdateRecord.id} for customer $customerId',
          );

          // Update deliveryData record
          await _pocketBaseClient
              .collection('deliveryData')
              .update(
                customerId,
                body: {
                  'deliveryUpdates+': [deliveryUpdateRecord.id],
                },
              );

          debugPrint('✅ Successfully updated status for customer: $customerId');
        } catch (e) {
          debugPrint('⚠️ Failed to update customer $customerId: $e');
          // Continue with next customer instead of breaking whole process
        }
      }

      debugPrint(
        '🎉 Bulk update completed for ${customerIds.length} customers',
      );
    } catch (e) {
      debugPrint('❌ Bulk operation failed: ${e.toString()}');
      throw ServerException(
        message:
            e is ServerException
                ? e.message
                : 'Bulk operation failed: ${e.toString()}',
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }

  @override
  Future<void> completeDelivery(DeliveryDataEntity deliveryData) async {
    try {
      debugPrint(
        '🔄 Processing delivery completion for delivery data: ${deliveryData.id}',
      );

      // Extract delivery data ID
      final deliveryDataId = deliveryData.id;
      if (deliveryDataId == null || deliveryDataId.isEmpty) {
        throw const ServerException(
          message: 'Invalid delivery data ID',
          statusCode: '400',
        );
      }

      // Get trip ID from delivery data
      final tripId = deliveryData.trip.target?.id;
      if (tripId == null) {
        throw const ServerException(
          message: 'Trip ID not found for delivery data',
          statusCode: '404',
        );
      }

      debugPrint('🚛 Found trip ID: $tripId');

      // Step 1: Add "End Delivery" status to delivery updates
      debugPrint('📝 Adding "End Delivery" status to delivery updates');

      // Get the "End Delivery" status from deliveryStatusChoices
      final endDeliveryStatus = await _pocketBaseClient
          .collection('deliveryStatusChoices')
          .getFirstListItem('title = "End Delivery"');

      // Create delivery update with "End Delivery" status
      final currentTime = DateTime.now().toIso8601String();
      final deliveryUpdateRecord = await _pocketBaseClient
          .collection('deliveryUpdate')
          .create(
            body: {
              'deliveryData': deliveryDataId,
              'status': endDeliveryStatus.id,
              'title': endDeliveryStatus.data['title'],
              'subtitle': endDeliveryStatus.data['subtitle'],
              'created': currentTime,
              'time': currentTime,
              'isAssigned': true,
            },
          );

      debugPrint('✅ Created "End Delivery" update: ${deliveryUpdateRecord.id}');

      // Update delivery data with the new delivery update
      await _pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryDataId,
            body: {
              'invoiceStatus': 'delivered',
              'deliveryUpdates+': [deliveryUpdateRecord.id],
            },
          );

      debugPrint('✅ Updated delivery data with "End Delivery" status');

      // Step 2: Find delivery receipt for this delivery data
      debugPrint(
        '🔍 Looking for delivery receipt with delivery data: $deliveryDataId',
      );

      final deliveryReceiptRecords = await _pocketBaseClient
          .collection('deliveryReceipt')
          .getList(filter: 'deliveryData = "$deliveryDataId"');

      if (deliveryReceiptRecords.items.isEmpty) {
        throw const ServerException(
          message: 'Delivery receipt not found for this delivery data',
          statusCode: '404',
        );
      }

      final deliveryReceiptRecord = deliveryReceiptRecords.items.first;
      debugPrint('✅ Found delivery receipt: ${deliveryReceiptRecord.id}');

      // Step 3: Extract customer and invoices IDs from delivery data
      debugPrint('🔍 Extracting customer and invoices data from delivery data');

      final customerId = deliveryData.customer.target?.id;
      final invoices = deliveryData.invoices;
      final invoiceIds = invoices.map((invoice) => invoice.id).toList();

      debugPrint('👤 Customer ID: $customerId');
      debugPrint('📄 Invoice IDs: $invoiceIds');
      debugPrint('📦 Number of invoices: ${invoices.length}');

      if (customerId == null || customerId.isEmpty) {
        throw const ServerException(
          message: 'Customer ID not found in delivery data',
          statusCode: '404',
        );
      }

      if (invoiceIds.isEmpty) {
        throw const ServerException(
          message: 'No invoices found in delivery data',
          statusCode: '404',
        );
      }

      // Step 4: Create record in deliveryCollection with customer and invoices
      debugPrint(
        '📝 Creating delivery collection record with customer and invoices',
      );

      final deliveryCollectionData = {
        'deliveryData': deliveryDataId,
        'trip': tripId,
        'deliveryReceipt': deliveryReceiptRecord.id,
        'customer': customerId,
        'invoice':
            invoiceIds.isNotEmpty
                ? invoiceIds.first
                : null, // Primary invoice for backward compatibility
        'invoices': invoiceIds, // Multiple invoices
        'invoiceStatus': 'completed',
        'completedAt': DateTime.now().toUtc().toIso8601String(),
        'status': 'completed',
      };

      debugPrint('📋 Delivery collection data:');
      debugPrint('   - Delivery Data: $deliveryDataId');
      debugPrint('   - Trip: $tripId');
      debugPrint('   - Delivery Receipt: ${deliveryReceiptRecord.id}');
      debugPrint('   - Customer: $customerId');
      debugPrint(
        '   - Primary Invoice: ${invoiceIds.isNotEmpty ? invoiceIds.first : "null"}',
      );
      debugPrint('   - All Invoices: $invoiceIds');
      debugPrint('   - Status: completed');

      final deliveryCollectionRecord = await _pocketBaseClient
          .collection('deliveryCollection')
          .create(body: deliveryCollectionData);

      debugPrint(
        '✅ Created delivery collection record: ${deliveryCollectionRecord.id}',
      );

      // Update user performance - increment successful deliveries
      try {
        debugPrint('📊 Updating user performance for successful delivery');

        // Get user ID from trip ticket
        final tripTicketRecord = await _pocketBaseClient
            .collection('tripticket')
            .getOne(tripId);

        final userId = tripTicketRecord.data['user'];
        if (userId != null && userId.isNotEmpty) {
          debugPrint('👤 Found user ID from trip: $userId');

          // Find user performance record
          final userPerformanceRecords = await _pocketBaseClient
              .collection('userPerformance')
              .getList(filter: 'user = "$userId"');

          if (userPerformanceRecords.items.isNotEmpty) {
            // Update existing record
            final userPerformanceRecord = userPerformanceRecords.items.first;
            final currentSuccessfulDeliveries =
                userPerformanceRecord.data['successfulDeliveries'] ?? 0;
            final newSuccessfulDeliveries =
                (currentSuccessfulDeliveries is String)
                    ? (int.tryParse(currentSuccessfulDeliveries) ?? 0) + 1
                    : (currentSuccessfulDeliveries as int) + 1;

            debugPrint(
              '📈 Incrementing successful deliveries: $currentSuccessfulDeliveries → $newSuccessfulDeliveries',
            );

            // Calculate new success rate
            final totalDeliveries =
                userPerformanceRecord.data['totalDeliveries'] ?? 0;
            final totalDelCount =
                (totalDeliveries is String)
                    ? (int.tryParse(totalDeliveries) ?? 0)
                    : (totalDeliveries as int);

            final successRate =
                totalDelCount > 0
                    ? (newSuccessfulDeliveries / totalDelCount * 100)
                    : 0.0;

            await _pocketBaseClient
                .collection('userPerformance')
                .update(
                  userPerformanceRecord.id,
                  body: {
                    'successfulDeliveries': newSuccessfulDeliveries.toString(),
                    'successRate': successRate.toStringAsFixed(2),
                    'updated': DateTime.now().toIso8601String(),
                  },
                );

            debugPrint(
              '✅ User performance updated - Successful deliveries: $newSuccessfulDeliveries, Success rate: ${successRate.toStringAsFixed(2)}%',
            );
          } else {
            debugPrint('⚠️ No user performance record found for user: $userId');
          }
        } else {
          debugPrint('⚠️ No user ID found in trip ticket');
        }
      } catch (e) {
        debugPrint(
          '⚠️ Failed to update user performance for successful delivery: $e',
        );
        // Don't throw error here as delivery completion should still succeed
      }

      // Step 5: Update delivery team stats
      debugPrint('🔄 Updating delivery team statistics');

      // Get delivery team using trip ID
      final deliveryTeamRecords = await _pocketBaseClient
          .collection('deliveryTeam')
          .getList(filter: 'tripTicket = "$tripId"');

      if (deliveryTeamRecords.items.isEmpty) {
        throw const ServerException(
          message: 'Delivery team not found for this trip',
          statusCode: '404',
        );
      }

      final deliveryTeamRecord = deliveryTeamRecords.items.first;
      debugPrint('✅ Found delivery team: ${deliveryTeamRecord.id}');

      // Calculate new stats
      final currentActiveDeliveries =
          int.tryParse(
            deliveryTeamRecord.data['activeDeliveries']?.toString() ?? '0',
          ) ??
          0;

      final currentTotalDelivered =
          int.tryParse(
            deliveryTeamRecord.data['totalDelivered']?.toString() ?? '0',
          ) ??
          0;

      final newActiveDeliveries =
          (currentActiveDeliveries - 1).clamp(0, double.infinity).toInt();
      final newTotalDelivered = currentTotalDelivered + 1;

      debugPrint('📊 Delivery team stats update:');
      debugPrint(
        '   - Active deliveries: $currentActiveDeliveries -> $newActiveDeliveries',
      );
      debugPrint(
        '   - Total delivered: $currentTotalDelivered -> $newTotalDelivered',
      );

      // Update delivery team stats
      await _pocketBaseClient
          .collection('deliveryTeam')
          .update(
            deliveryTeamRecord.id,
            body: {
              'activeDeliveries': newActiveDeliveries.toString(),
              'totalDelivered': newTotalDelivered.toString(),
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Updated delivery team statistics');

      // Step 6: Update trip ticket with completed delivery collection
      debugPrint('🔄 Updating trip ticket with completed delivery');

      await _pocketBaseClient
          .collection('tripticket')
          .update(
            tripId,
            body: {
              'deliveryCollection+': [deliveryCollectionRecord.id],
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Updated trip ticket with delivery collection');
      debugPrint(
        '🎉 Successfully completed delivery process with customer and invoice data',
      );
    } catch (e) {
      debugPrint('❌ Failed to complete delivery: ${e.toString()}');
      throw ServerException(
        message: 'Failed to complete delivery: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<DataMap> checkEndDeliverStatus(String tripId) async {
    try {
      debugPrint('🔍 Checking end delivery status for trip: $tripId');

      // Extract trip ID if received as JSON
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      // Get customers using trip ID
      final customerRecords = await _pocketBaseClient
          .collection('deliveryData')
          .getFullList(
            filter: 'trip = "$actualTripId"',
            expand: 'deliveryUpdates',
          );

      final totalCustomers = customerRecords.length;
      debugPrint('📦 Total customers in trip: $totalCustomers');

      final completedDeliveries =
          customerRecords.where((customer) {
            final deliveryStatuses =
                customer.expand['deliveryUpdates'] as List? ?? [];
            final hasEndDelivery = deliveryStatuses.any((status) {
              final title = status.data['title'].toString().toLowerCase();
              if (title == 'end delivery') {
                debugPrint(
                  '   ✅ Customer ${customer.data['storeName']} has End Delivery status',
                );
                return true;
              }
              if (title == 'mark as undelivered') {
                debugPrint(
                  '   ⚠️ Customer ${customer.data['storeName']} is marked Undelivered',
                );
                return true;
              }
              return false;
            });
            return hasEndDelivery;
          }).length;

      debugPrint('📊 Delivery Status Summary:');
      debugPrint('   - Total Customers: $totalCustomers');
      debugPrint('   - Completed Deliveries: $completedDeliveries');
      debugPrint(
        '   - Pending Deliveries: ${totalCustomers - completedDeliveries}',
      );

      return {
        'total': totalCustomers,
        'completed': completedDeliveries,
        'pending': totalCustomers - completedDeliveries,
      };
    } catch (e) {
      debugPrint('❌ Error checking end delivery status: $e');
      throw ServerException(
        message: 'Failed to check end delivery status: $e',
        statusCode: '500',
      );
    }
  }

  @override
  Future<void> initializePendingStatus(List<String> customerIds) async {
    try {
      debugPrint('🔄 Initializing pending status for customers');

      final pendingStatus = await _pocketBaseClient
          .collection('deliveryStatusChoices')
          .getFirstListItem('title = "Pending"');

      for (final customerId in customerIds) {
        // Check if customer already has a pending status
        final customerRecord = await _pocketBaseClient
            .collection('customers')
            .getOne(customerId, expand: 'deliveryStatus');

        final existingStatuses =
            customerRecord.expand['deliveryStatus'] as List? ?? [];
        final hasPendingStatus = existingStatuses.any(
          (status) => status.data['title'] == 'Pending',
        );

        if (!hasPendingStatus) {
          final currentTime = DateTime.now().toIso8601String();
          final deliveryUpdateRecord = await _pocketBaseClient
              .collection('deliveryUpdate')
              .create(
                body: {
                  'customer': customerId,
                  'deliveryData': customerId,
                  'status': pendingStatus.id,
                  'title': pendingStatus.data['title'],
                  'subtitle': pendingStatus.data['subtitle'],
                  'created': currentTime,
                  'time': currentTime,
                  'isAssigned': true,
                },
              );

          await _pocketBaseClient
              .collection('deliveryData')
              .update(
                customerId,
                body: {
                  'deliveryStatus': [deliveryUpdateRecord.id],
                },
              );
        }
      }

      debugPrint('✅ Successfully initialized pending status');
    } catch (e) {
      debugPrint('❌ Failed to initialize pending status: $e');
      throw ServerException(
        message: 'Failed to initialize pending status: $e',
        statusCode: '500',
      );
    }
  }

  @override
  Future<void> createDeliveryStatus(
    String customerId, {
    required String title,
    required String subtitle,
    required DateTime time,
    required bool isAssigned,
    required String image,
  }) async {
    try {
      debugPrint('📝 Creating delivery status for customer: $customerId');

      final files = <MultipartFile>[];

      if (image.isNotEmpty) {
        try {
          final imageFile = File(image);
          if (await imageFile.exists()) {
            debugPrint('📸 Processing delivery status image...');

            // Compress the image to very small size
            final compressedImageBytes = await _compressImageToSmallSize(image);
            if (compressedImageBytes != null) {
              files.add(
                MultipartFile.fromBytes(
                  'image',
                  compressedImageBytes,
                  filename:
                      'delivery_status_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
                ),
              );
              debugPrint(
                '✅ Added compressed delivery status image (${compressedImageBytes.length} bytes)',
              );
            } else {
              // Fallback to original if compression fails
              final originalBytes = await imageFile.readAsBytes();
              files.add(
                MultipartFile.fromBytes(
                  'image',
                  originalBytes,
                  filename:
                      'delivery_status_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
                ),
              );
              debugPrint(
                '⚠️ Using original image (compression failed): ${originalBytes.length} bytes',
              );
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error processing delivery status image: $e');
        }
      }

      // Calculate total file size
      final totalSize = files.fold<int>(0, (sum, file) => sum + file.length);
      debugPrint(
        '📦 Total upload size: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      debugPrint('📦 Creating delivery status with ${files.length} files');
      debugPrint('⏱️ Starting optimized remote creation...');

      final startTime = DateTime.now();

      final deliveryUpdateRecord = await _pocketBaseClient
          .collection('deliveryUpdate')
          .create(
            body: {
              'deliveryData': customerId,
              'title': title,
              'subtitle': subtitle,
              'time': time.toIso8601String(),
              'isAssigned': true,
            },
            files: files,
          );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('⏱️ Remote creation took: ${duration.inMilliseconds}ms');

      debugPrint('✅ Created delivery status: ${deliveryUpdateRecord.id}');

      await _pocketBaseClient
          .collection('deliveryData')
          .update(
            customerId,
            body: {
              'deliveryUpdates+': [deliveryUpdateRecord.id],
            },
          );

      debugPrint('✅ Updated customer with new delivery status');
    } catch (e) {
      debugPrint('❌ Failed to create delivery status: $e');
      throw ServerException(
        message: 'Failed to create delivery status: $e',
        statusCode: '500',
      );
    }
  }

  /// Compress image file to very small size for delivery status
  Future<Uint8List?> _compressImageToSmallSize(String imagePath) async {
    try {
      debugPrint(
        '🗜️ Compressing delivery status image to very small size: $imagePath',
      );

      // First compression pass - aggressive settings for very small file size
      final firstPassBytes = await FlutterImageCompress.compressWithFile(
        imagePath,
        quality: 50, // Lower quality for smaller size
        minWidth: 600, // Smaller max width
        minHeight: 400, // Smaller max height
        format: CompressFormat.jpeg,
      );

      if (firstPassBytes == null) {
        debugPrint('❌ First compression pass failed');
        return null;
      }

      // Check if we need a second pass for even smaller size
      const maxSizeBytes = 500 * 1024; // 500KB max
      if (firstPassBytes.length > maxSizeBytes) {
        debugPrint(
          '🔄 File still too large (${firstPassBytes.length} bytes), applying second compression pass...',
        );

        // Create temporary file for second pass
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
          '${tempDir.path}/temp_delivery_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await tempFile.writeAsBytes(firstPassBytes);

        // Second compression pass - even more aggressive
        final secondPassBytes = await FlutterImageCompress.compressWithFile(
          tempFile.path,
          quality: 30, // Very low quality
          minWidth: 400, // Even smaller dimensions
          minHeight: 300,
          format: CompressFormat.jpeg,
        );

        // Clean up temp file
        try {
          await tempFile.delete();
        } catch (e) {
          debugPrint('⚠️ Failed to delete temp file: $e');
        }

        if (secondPassBytes != null) {
          final originalSize = await File(imagePath).length();
          debugPrint(
            '📊 Delivery status image compressed (2 passes): ${originalSize} bytes -> ${secondPassBytes.length} bytes',
          );
          debugPrint(
            '📉 Compression ratio: ${((originalSize - secondPassBytes.length) / originalSize * 100).toStringAsFixed(1)}%',
          );
          return secondPassBytes;
        } else {
          debugPrint(
            '⚠️ Second compression pass failed, using first pass result',
          );
          final originalSize = await File(imagePath).length();
          debugPrint(
            '📊 Delivery status image compressed (1 pass): ${originalSize} bytes -> ${firstPassBytes.length} bytes',
          );
          debugPrint(
            '📉 Compression ratio: ${((originalSize - firstPassBytes.length) / originalSize * 100).toStringAsFixed(1)}%',
          );
          return firstPassBytes;
        }
      } else {
        final originalSize = await File(imagePath).length();
        debugPrint(
          '📊 Delivery status image compressed: ${originalSize} bytes -> ${firstPassBytes.length} bytes',
        );
        debugPrint(
          '📉 Compression ratio: ${((originalSize - firstPassBytes.length) / originalSize * 100).toStringAsFixed(1)}%',
        );
        return firstPassBytes;
      }
    } catch (e) {
      debugPrint('⚠️ Delivery status image compression failed: $e');
      // Fallback to original file
      try {
        final originalBytes = await File(imagePath).readAsBytes();
        debugPrint(
          '📄 Using original image file: ${originalBytes.length} bytes',
        );
        return originalBytes;
      } catch (fallbackError) {
        debugPrint('❌ Failed to read original image file: $fallbackError');
        return null;
      }
    }
  }

  @override
  Future<void> pinArrivedLocation(String deliveryId) async {
    try {
      debugPrint('📍 Pinning arrived location for delivery: $deliveryId');

      // Get current location using the location service
      final position = await LocationService.getCurrentLocation();

      debugPrint(
        '📍 Current location: ${position.latitude}, ${position.longitude}',
      );

      // Update delivery data with location
      await _pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryId,
            body: {
              'pinLang': position.longitude,
              'pinLong': position.latitude,
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Successfully pinned location for delivery: $deliveryId');
      debugPrint(
        '📍 Pinned coordinates: lat=${position.latitude}, lng=${position.longitude}',
      );
    } catch (e) {
      debugPrint('❌ Failed to pin arrived location: $e');
      throw ServerException(
        message: 'Failed to pin arrived location: $e',
        statusCode: '500',
      );
    }
  }
}
