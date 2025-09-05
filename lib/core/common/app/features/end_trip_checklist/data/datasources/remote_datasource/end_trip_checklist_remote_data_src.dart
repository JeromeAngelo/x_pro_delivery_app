import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../model/end_trip_checklist_model.dart';

abstract class EndTripChecklistRemoteDataSource {
  Future<List<EndTripChecklistModel>> generateEndTripChecklist(String tripId);
  Future<bool> checkEndTripChecklistItem(String id);
  Future<List<EndTripChecklistModel>> loadEndTripChecklist(String tripId);
}

class EndTripChecklistRemoteDataSourceImpl
    implements EndTripChecklistRemoteDataSource {
  const EndTripChecklistRemoteDataSourceImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;
@override
Future<List<EndTripChecklistModel>> generateEndTripChecklist(String tripId) async {
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

    // Check for existing checklists
    final existingChecklists = await _pocketBaseClient
        .collection('endTripChecklist')
        .getList(filter: 'trip = "$actualTripId"');

    if (existingChecklists.items.isNotEmpty) {
      debugPrint('📝 Found existing checklists, returning those');
      return existingChecklists.items
          .map((record) => EndTripChecklistModel.fromJson(record.toJson()))
          .toList();
    }

    // Create new checklist items with trip reference
    final checklistItems = [
      {
        'trip': actualTripId,
        'objectName': 'Collections',
        'isChecked': false,
        'status': 'pending',
        'description': 'Check all the collections',
        'created': DateTime.now().toIso8601String(),
      },
      {
        'trip': actualTripId,
        'objectName': 'Pushcarts',
        'description': 'Check all the pushcarts',
        'isChecked': false,
        'status': 'pending',
        'created': DateTime.now().toIso8601String(),
      },
      {
        'trip': actualTripId,
        'objectName': 'Remittance',
        'description': 'Check all the remittances',
        'isChecked': false,
        'status': 'pending',
        'created': DateTime.now().toIso8601String(),
      }
    ];

    debugPrint('📝 Creating new checklist items');
    final createdItems = await Future.wait(checklistItems.map((item) async {
      final response = await _pocketBaseClient
          .collection('endTripChecklist')
          .create(body: item);
      debugPrint('✅ Created item: ${response.id}');
      return response;
    }));

    // Update tripticket with checklist references
    final checklistIds = createdItems.map((item) => item.id).toList();
    await _pocketBaseClient.collection('tripticket').update(
      actualTripId,
      body: {
        'endTripChecklists': checklistIds,
      },
    );
    debugPrint('✅ Updated tripticket with checklist IDs: $checklistIds');

    return createdItems
        .map((record) => EndTripChecklistModel.fromJson(record.toJson()))
        .toList();
  } catch (e) {
    debugPrint('❌ Remote: Generation failed - ${e.toString()}');
    throw ServerException(message: e.toString(), statusCode: '500');
  }
}


@override
Future<bool> checkEndTripChecklistItem(String id) async {
  try {
    debugPrint('🔄 Updating checklist item: $id');

    await _pocketBaseClient.collection('endTripChecklist').update(
      id,
      body: {
        'isChecked': true,
        'status': 'completed',
        'timeCompleted': DateTime.now().toIso8601String(),
      },
    );

    debugPrint('✅ Checklist item updated successfully');
    return true;
  } catch (e) {
    debugPrint('❌ Failed to update checklist item: ${e.toString()}');
    throw ServerException(message: e.toString(), statusCode: '500');
  }
}

@override
Future<List<EndTripChecklistModel>> loadEndTripChecklist(String tripId) async {
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

    final records = await _pocketBaseClient
        .collection('endTripChecklist')
        .getFullList(
          filter: 'trip = "$actualTripId"',
          expand: 'trip',
        );

    debugPrint('✅ Retrieved ${records.length} end trip checklist items');

    final checklists = records.map((record) {
      final mappedData = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'objectName': record.data['objectName'] ?? '',
        'isChecked': record.data['isChecked'] ?? false,
        'status': record.data['status'] ?? 'pending',
        'timeCompleted': record.data['timeCompleted'],
        'description': record.data['description'] ?? '',
        'trip': actualTripId,
        'expand': {
          'trip': record.expand['trip']?.map((trip) => trip.data).first,
        }
      };
      return EndTripChecklistModel.fromJson(mappedData);
    }).toList();

    debugPrint('✨ Successfully mapped ${checklists.length} end trip checklist items');
    return checklists;
  } catch (e) {
    debugPrint('❌ End trip checklist fetch failed: ${e.toString()}');
    throw ServerException(
      message: 'Failed to load end trip checklist: ${e.toString()}',
      statusCode: '500',
    );
  }
}

}
