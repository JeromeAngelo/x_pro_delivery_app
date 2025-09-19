import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'dart:typed_data' show Uint8List;
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../../trip/data/models/trip_models.dart';
import '../../model/trip_update_model.dart';


abstract class TripUpdateRemoteDatasource {
  Future<List<TripUpdateModel>> getTripUpdates(String tripId);
  Future<void> createTripUpdate({
    required String tripId,
    required String description,
    required String image,
    required String latitude,
    required String longitude,
    required TripUpdateStatus status,
  });
}

class TripUpdateRemoteDatasourceImpl implements TripUpdateRemoteDatasource {
  const TripUpdateRemoteDatasourceImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

 @override
Future<void> createTripUpdate({
  required String tripId,
  required String description,
  required String image,
  required String latitude,
  required String longitude,
  required TripUpdateStatus status,
}) async {
  try {
    // Extract trip ID if we received a JSON object
    String actualTripId;
    if (tripId.startsWith('{')) {
      final tripData = jsonDecode(tripId);
      actualTripId = tripData['id'];
    } else {
      actualTripId = tripId;
    }
    
    debugPrint('🎯 Using trip ID: $actualTripId');
    debugPrint('🔄 Creating trip update with status: ${status.toString().split('.').last}');

    final files = <MultipartFile>[];

    if (image.isNotEmpty) {
      try {
        final imageFile = File(image);
        if (await imageFile.exists()) {
          debugPrint('📸 Processing trip update image...');
          
          // Compress the image using the same method as delivery receipt
          final compressedImageBytes = await _compressImage(image);
          if (compressedImageBytes != null) {
            files.add(MultipartFile.fromBytes(
              'image',
              compressedImageBytes,
              filename: 'trip_update_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ));
            debugPrint('✅ Added compressed trip update image (${compressedImageBytes.length} bytes)');
          } else {
            // Fallback to original if compression fails
            final originalBytes = await imageFile.readAsBytes();
            files.add(MultipartFile.fromBytes(
              'image',
              originalBytes,
              filename: 'trip_update_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ));
            debugPrint('⚠️ Using original image (compression failed): ${originalBytes.length} bytes');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error processing trip update image: $e');
      }
    }

    // Use the enhanced DateTime formatting
    final formattedDate = _formatDateTimeForPocketBase(DateTime.now());

    // Calculate total file size
    final totalSize = files.fold<int>(0, (sum, file) => sum + file.length);
    debugPrint('📦 Total upload size: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');

    debugPrint('📦 Creating trip update with ${files.length} files');
    debugPrint('⏱️ Starting optimized remote creation...');

    final startTime = DateTime.now();

    final tripUpdateRecord = await _pocketBaseClient.collection('tripUpdates').create(
      body: {
        'trip': actualTripId,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'date': formattedDate, // Use formatted date
        'status': status.toString().split('.').last,
      },
      files: files,
    );

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    debugPrint('⏱️ Remote creation took: ${duration.inMilliseconds}ms');

    debugPrint('✅ Created trip update: ${tripUpdateRecord.id}');

    await _pocketBaseClient.collection('tripticket').update(
      actualTripId,
      body: {
        'trip_update_list+': [tripUpdateRecord.id],
      },
    );

      // 🔔 Create notification entry
    await _pocketBaseClient.collection('notifications').create(
      body: {
        'trip': tripId,
        'type': 'tripUpdate',
        'created': formattedDate,
        'isRead': false,
        'tripUpdate': tripUpdateRecord.id,
      },
    );

    debugPrint('✅ Updated trip with new update record');
  } catch (e) {
    debugPrint('❌ Failed to create trip update: $e');
    throw ServerException(
      message: 'Failed to create trip update: $e',
      statusCode: '500',
    );
  }
}

/// Compress image file to reduce size
Future<Uint8List?> _compressImage(String imagePath) async {
  try {
    debugPrint('🗜️ Compressing trip update image: $imagePath');
    
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      imagePath,
      quality: 70, // 70% quality
      minWidth: 800, // Max width 800px
      minHeight: 600, // Max height 600px
      format: CompressFormat.jpeg,
    );
    
    if (compressedBytes != null) {
      final originalSize = await File(imagePath).length();
      debugPrint('📊 Trip update image compressed: $originalSize bytes -> ${compressedBytes.length} bytes');
      debugPrint('📉 Compression ratio: ${((originalSize - compressedBytes.length) / originalSize * 100).toStringAsFixed(1)}%');
    }
    
    return compressedBytes;
  } catch (e) {
    debugPrint('⚠️ Trip update image compression failed: $e');
    // Fallback to original file
    try {
      return await File(imagePath).readAsBytes();
    } catch (fallbackError) {
      debugPrint('❌ Failed to read original image file: $fallbackError');
      return null;
    }
  }
}

// Enhanced getTripUpdates with proper DateTime parsing
@override
Future<List<TripUpdateModel>> getTripUpdates(String tripId) async {
  try {
    // Extract trip ID if we received a JSON object
    String actualTripId;
    if (tripId.startsWith('{')) {
      final tripData = jsonDecode(tripId);
      actualTripId = tripData['id'];
    } else {
      actualTripId = tripId;
    }
    
    debugPrint('🎯 Using trip ID: $actualTripId');

    final records = await _pocketBaseClient.collection('tripUpdates').getFullList(
      filter: 'trip = "$actualTripId"',
      expand: 'trip',
      sort: '-created', // Sort by creation date, newest first
    );

    debugPrint('✅ Retrieved ${records.length} trip updates from API');

    final updates = records.map((record) {
      debugPrint('🔄 Processing trip update: ${record.id}');
      
      // Process the trip update record similar to delivery data processing
      return _processTripUpdateRecord(record, actualTripId);
    }).toList();

    debugPrint('✨ Successfully mapped ${updates.length} trip updates');
    return updates;

  } catch (e) {
    debugPrint('❌ Trip updates fetch failed: ${e.toString()}');
    throw ServerException(
      message: 'Failed to load trip updates: ${e.toString()}',
      statusCode: '500',
    );
  }
}

/// Process a trip update record similar to delivery data processing
TripUpdateModel _processTripUpdateRecord(RecordModel record, String tripId) {
  try {
    // Process expanded trip data if available
    TripModel? tripModel;
    if (record.expand['trip'] != null) {
      final tripData = record.expand['trip'];
      if (tripData is List && tripData!.isNotEmpty) {
        final tripRecord = tripData[0];
        tripModel = TripModel.fromJson({
          'id': tripRecord.id,
          'collectionId': tripRecord.collectionId,
          'collectionName': tripRecord.collectionName,
          'tripNumberId': tripRecord.data['tripNumberId'],
          'qrCode': tripRecord.data['qrCode'],
          'isAccepted': tripRecord.data['isAccepted'],
          'isEndTrip': tripRecord.data['isEndTrip'],
        });
      }
    } else if (record.data['trip'] != null) {
      tripModel = TripModel(id: record.data['trip'].toString());
    }

    // Parse dates safely
    DateTime? parsedDate;
    DateTime? createdDate;
    DateTime? updatedDate;

    // Parse the main date field
    if (record.data['date'] != null) {
      parsedDate = _parseDateTimeFromResponse(record.data['date']);
    }

    // Parse created date
    if (record.data['created'] != null) {
      createdDate = _parseDateTimeFromResponse(record.data['created']);
    }

    // Parse updated date
    if (record.data['updated'] != null) {
      updatedDate = _parseDateTimeFromResponse(record.data['updated']);
    }

    // Parse status safely
    TripUpdateStatus? status;
    final statusString = record.data['status'];
    if (statusString != null && statusString is String) {
      try {
        status = _parseTripUpdateStatus(statusString);
      } catch (e) {
        debugPrint('⚠️ Failed to parse status "$statusString": $e');
        status = TripUpdateStatus.others; // Default fallback
      }
    }

    // Create the mapped data
    final mappedData = {
      'id': record.id,
      'collectionId': record.collectionId,
      'collectionName': record.collectionName,
      'description': record.data['description'] ?? '',
      'status': status?.name ?? 'others',
      'latitude': record.data['latitude']?.toString() ?? '',
      'longitude': record.data['longitude']?.toString() ?? '',
      'date': parsedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'created': createdDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated': updatedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'trip': tripId,
      'image': record.data['image'] ?? '',
      'expand': {
        'trip': tripModel?.toJson(),
      }
    };

    debugPrint('✅ Successfully processed trip update: ${record.id}');
    return TripUpdateModel.fromJson(mappedData);

  } catch (e) {
    debugPrint('❌ Error processing trip update record ${record.id}: $e');
    
    // Return a minimal valid model as fallback
    return TripUpdateModel.fromJson({
      'id': record.id,
      'collectionId': record.collectionId,
      'collectionName': record.collectionName,
      'description': record.data['description'] ?? 'Error loading description',
      'status': _parseTripUpdateStatus,
      'latitude': '',
      'longitude': '',
      'date': DateTime.now().toIso8601String(),
      'created': DateTime.now().toIso8601String(),
      'updated': DateTime.now().toIso8601String(),
      'trip': tripId,
      'image': '',
    });
  }
}

/// Parse TripUpdateStatus from string
TripUpdateStatus _parseTripUpdateStatus(String statusString) {
  final normalizedStatus = statusString.toLowerCase().trim();
  debugPrint('🎯 TRIP STATUS: Parsing "$statusString" → normalized: "$normalizedStatus"');

  switch (normalizedStatus) {
    case 'generalupdate':
      return TripUpdateStatus.generalUpdate;
    case 'refuelling':
      return TripUpdateStatus.refuelling;
    case 'roadclosure':
      return TripUpdateStatus.roadClosure;
    case 'vehiclebreakdown':
      return TripUpdateStatus.vehicleBreakdown;
    case 'none':
      return TripUpdateStatus.none;
   
    case 'others':
    default:
      debugPrint('⚠️ TRIP STATUS: Unmatched status "$normalizedStatus", defaulting to others');
      return TripUpdateStatus.others;
  }
}

// Enhanced helper function to parse DateTime from various formats (same as delivery data)
DateTime? _parseDateTimeFromResponse(dynamic dateValue) {
  if (dateValue == null) {
    debugPrint('⚠️ Date value is null, using current time');
    return DateTime.now();
  }
  
  try {
    if (dateValue is String) {
      // Handle various date formats that might come from PocketBase
      if (dateValue.isEmpty) {
        debugPrint('⚠️ Date string is empty, using current time');
        return DateTime.now();
      }
      
      debugPrint('📅 Parsing date string: $dateValue');
      
      // Try ISO 8601 format first (most common)
      try {
        final parsed = DateTime.parse(dateValue);
        debugPrint('✅ Successfully parsed ISO date: $parsed');
        return parsed;
      } catch (e) {
        debugPrint('⚠️ Failed to parse as ISO format: $e');
      }
      
      // Try with timezone suffix variations
      try {
        String cleanedDate = dateValue;
        
        // Remove various timezone indicators
        cleanedDate = cleanedDate
            .replaceAll('Z', '')
            .replaceAll('+00:00', '')
            .replaceAll('UTC', '')
            .trim();
            
        // If it has 'T', try parsing as ISO without timezone
        if (cleanedDate.contains('T')) {
          final parsed = DateTime.parse(cleanedDate);
          debugPrint('✅ Successfully parsed cleaned ISO date: $parsed');
          return parsed;
        }
        
        // Try replacing T with space for alternative format
        cleanedDate = cleanedDate.replaceAll('T', ' ');
        final parsed = DateTime.parse(cleanedDate);
        debugPrint('✅ Successfully parsed space-separated date: $parsed');
        return parsed;
      } catch (e) {
        debugPrint('⚠️ Failed to parse cleaned format: $e');
      }
      
      // Try manual parsing for custom formats like "YYYY-MM-DD HH:mm:ss"
      try {
        final dateRegex = RegExp(r'(\d{4})-(\d{2})-(\d{2})[\s|T](\d{2}):(\d{2}):(\d{2})');
        final match = dateRegex.firstMatch(dateValue);
        
        if (match != null) {
          final parsed = DateTime(
            int.parse(match.group(1)!), // year
            int.parse(match.group(2)!), // month
            int.parse(match.group(3)!), // day
            int.parse(match.group(4)!), // hour
            int.parse(match.group(5)!), // minute
            int.parse(match.group(6)!), // second
          );
          debugPrint('✅ Successfully parsed with regex: $parsed');
          return parsed;
        }
      } catch (e) {
        debugPrint('⚠️ Failed to parse with regex: $e');
      }
      
      // Try parsing just the date part if time parsing fails
      try {
        final dateOnlyRegex = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
        final match = dateOnlyRegex.firstMatch(dateValue);
        
        if (match != null) {
          final parsed = DateTime(
            int.parse(match.group(1)!), // year
            int.parse(match.group(2)!), // month
            int.parse(match.group(3)!), // day
          );
          debugPrint('✅ Successfully parsed date only: $parsed');
          return parsed;
        }
      } catch (e) {
        debugPrint('⚠️ Failed to parse date only: $e');
      }
      
    } else if (dateValue is DateTime) {
      debugPrint('✅ Date value is already DateTime: $dateValue');
      return dateValue;
    } else if (dateValue is int) {
      // Handle timestamp (milliseconds since epoch)
      try {
        final parsed = DateTime.fromMillisecondsSinceEpoch(dateValue);
        debugPrint('✅ Successfully parsed timestamp: $parsed');
        return parsed;
      } catch (e) {
        debugPrint('⚠️ Failed to parse timestamp: $e');
      }
    }
    
    debugPrint('⚠️ Unsupported date format: $dateValue (${dateValue.runtimeType})');
    return DateTime.now(); // Fallback to current time
    
  } catch (e) {
    debugPrint('❌ Error parsing DateTime: $e');
    debugPrint('📅 Using current time as fallback');
    return DateTime.now(); // Always return a valid DateTime
  }
}

String _formatDateTimeForPocketBase(DateTime dateTime) {
  try {
    // PocketBase expects ISO 8601 format with proper timezone
    // Format: YYYY-MM-DDTHH:mm:ss.sssZ
    final formattedDate = dateTime.toUtc().toIso8601String();
    
    debugPrint('📅 Formatted DateTime: $formattedDate');
    return formattedDate;
  } catch (e) {
    debugPrint('❌ Error formatting DateTime: $e');
    // Fallback to current time if formatting fails
    return DateTime.now().toUtc().toIso8601String();
  }
}

  
}
