import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/mixins/offline_first_mixin.dart';

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/accept_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/calculate_total_distance.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/check_end_trip_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/end_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/get_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/get_trip_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/get_trips_by_date_range.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/scan_qr_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/search_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/search_trip_by_details.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/update_trip_location.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/services/location_services.dart';

class TripBloc extends Bloc<TripEvent, TripState> with OfflineFirstMixin<TripEvent, TripState> {
  TripState? _cachedState;
  final GetTrip _getTrip;
  final GetTripById _getTripById;
  final SearchTrip _searchTrip;
  final AcceptTrip _acceptTrip;
  final DeliveryDataBloc _deliveryDataBloc;
  final CheckEndTripStatus _checkEndTripStatus;
  final TripUpdatesBloc _updateTimelineBloc;
  final UpdateTripLocation _updateTripLocation;
  final ConnectivityProvider _connectivity;

  final SearchTrips _searchTrips;
  final GetTripsByDateRange _getTripsByDateRange;
  final CalculateTotalTripDistance _calculateTotalTripDistance;
  final ScanQRUsecase _scanQRUsecase;
  final EndTrip _endTrip;

  // Field to store the subscription to the location updates
  StreamSubscription<double>? _locationSubscription;

  // Field to store the current tracked trip ID
  String? _trackedTripId;

  TripBloc({
    required GetTrip getTrip,
    required GetTripById getTripById,
    required DeliveryDataBloc deliveryDataBloc,
    required CalculateTotalTripDistance calculateTotalTripDistance,
    required SearchTrip searchTrip,
    required AcceptTrip acceptTrip,
    required TripUpdatesBloc updateTimelineBloc,
    required CheckEndTripStatus checkEndTripStatus,
    required SearchTrips searchTrips,
    required GetTripsByDateRange getTripsByDateRange,
    required ScanQRUsecase scanQRUsecase,
    required UpdateTripLocation updateTripLocation,
    required EndTrip endTrip,
    required ConnectivityProvider connectivity,
  }) : _getTrip = getTrip,
       _getTripById = getTripById,
       _searchTrip = searchTrip,
       _acceptTrip = acceptTrip,
       _deliveryDataBloc = deliveryDataBloc,
       _updateTimelineBloc = updateTimelineBloc,
       _checkEndTripStatus = checkEndTripStatus,
       _searchTrips = searchTrips,
       _getTripsByDateRange = getTripsByDateRange,
       _calculateTotalTripDistance = calculateTotalTripDistance,
       _scanQRUsecase = scanQRUsecase,
       _updateTripLocation = updateTripLocation,
       _endTrip = endTrip,
       _connectivity = connectivity,

       super(TripInitial()) {
    on<CalculateTripDistanceEvent>(_onCalculateTripDistance);
    on<LoadLocalTripByIdEvent>(_onLoadLocalTripById);
    on<GetTripEvent>(_onGetTrip);
    on<SearchTripEvent>(_onSearchTrip);
    on<AcceptTripEvent>(_onAcceptTrip);
    on<ClearTripSearchEvent>(_onClearSearch);
    on<LoadLocalTripEvent>(_onLoadLocalTrip);
    on<CheckEndTripOtpStatusEvent>(_onCheckEndTripOtpStatus);
    on<SearchTripsAdvancedEvent>(_onSearchTripsAdvanced);
    on<GetTripsByDateRangeEvent>(_onGetTripsByDateRange);
    on<GetTripByIdEvent>(_onGetTripById);
    on<ScanTripQREvent>(_onScanTripQR);
    on<EndTripEvent>(_onEndTrip);
    on<UpdateTripLocationEvent>(_onUpdateTripLocation);
    on<StartLocationTrackingEvent>(_onStartLocationTracking);
    on<StopLocationTrackingEvent>(_onStopLocationTracking);
  }

  Future<void> _onGetTripById(
    GetTripByIdEvent event,
    Emitter<TripState> emit,
  ) async {
    debugPrint('🔍 OFFLINE-FIRST: Loading trip by ID: ${event.tripId}');
    emit(TripLoading());

    await executeOfflineFirst(
      localOperation: () async {
        final result = await _getTripById.loadFromLocal(event.tripId);
        result.fold(
          (failure) => throw Exception(failure.message),
          (trip) => emit(TripByIdLoaded(trip, isFromLocal: true)),
        );
      },
      remoteOperation: () async {
        final result = await _getTripById(event.tripId);
        result.fold(
          (failure) => throw Exception(failure.message),
          (trip) => emit(TripByIdLoaded(trip)),
        );
      },
      onLocalSuccess: (data) {
        debugPrint('✅ Trip loaded from local cache');
      },
      onRemoteSuccess: (data) {
        debugPrint('✅ Trip synced from remote');
      },
      onError: (error) => emit(TripError(error)),
      connectivity: _connectivity,
    );
  }

  /// Legacy method - use GetTripByIdEvent with offline-first pattern instead
  Future<void> _onLoadLocalTripById(
    LoadLocalTripByIdEvent event,
    Emitter<TripState> emit,
  ) async {
    emit(TripLoading());
    debugPrint('📱 Loading local trip by ID: ${event.tripId}');

    final result = await _getTripById.loadFromLocal(event.tripId);

    result.fold((failure) => emit(TripError(failure.message)), (trip) {
      emit(TripByIdLoaded(trip, isFromLocal: true));

      // Background remote sync
      _onGetTripById(GetTripByIdEvent(event.tripId), emit);
    });
  }

  Future<void> _onScanTripQR(
    ScanTripQREvent event,
    Emitter<TripState> emit,
  ) async {
    emit(TripQRScanning());
    debugPrint('🔍 Processing QR scan: ${event.qrData}');

    final result = await _scanQRUsecase(event.qrData);

    result.fold((failure) => emit(TripError(failure.message)), (trip) {
      debugPrint('✅ QR scan successful');
      emit(TripQRScanned(trip));

      if (trip.id != null) {
        _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(trip.id!));
      }
      _updateTimelineBloc.add(LoadLocalTripUpdatesEvent(trip.id!));
    });
  }

  Future<void> _onLoadLocalTrip(
    LoadLocalTripEvent event,
    Emitter<TripState> emit,
  ) async {
    if (_cachedState != null) {
      emit(_cachedState!);
      return;
    }

    final result = await _getTrip.loadFromLocal();
    result.fold((failure) => emit(TripError(failure.message)), (trip) {
      if (trip.id != null) {
        _deliveryDataBloc.add(GetLocalDeliveryDataByIdEvent(trip.id!));
      }
      _updateTimelineBloc.add(LoadLocalTripUpdatesEvent(trip.id!));

      final newState = TripLoaded(
        trip: trip,
        customerState: _deliveryDataBloc.state,
        timelineState: _updateTimelineBloc.state,
        deliveryDataState: _deliveryDataBloc.state,
      );
      _cachedState = newState;
      emit(newState);
    });
  }

  Future<void> _onSearchTripsAdvanced(
    SearchTripsAdvancedEvent event,
    Emitter<TripState> emit,
  ) async {
    emit(TripSearching());

    final result = await _searchTrips(
      SearchTripsParams(
        tripNumberId: event.tripNumberId,
        startDate: event.startDate,
        endDate: event.endDate,
        isAccepted: event.isAccepted,
        isEndTrip: event.isEndTrip,
        deliveryTeamId: event.deliveryTeamId,
        vehicleId: event.vehicleId,
        personnelId: event.personnelId,
      ),
    );

    result.fold(
      (failure) => emit(TripError(failure.message)),
      (trips) => emit(TripsSearchResults(trips)),
    );
  }

  Future<void> _onGetTripsByDateRange(
    GetTripsByDateRangeEvent event,
    Emitter<TripState> emit,
  ) async {
    emit(TripSearching());

    final result = await _getTripsByDateRange(
      DateRangeParams(startDate: event.startDate, endDate: event.endDate),
    );

    result.fold(
      (failure) => emit(TripError(failure.message)),
      (trips) => emit(TripDateRangeResults(trips)),
    );
  }

  Future<void> _onGetTrip(GetTripEvent event, Emitter<TripState> emit) async {
    if (_cachedState != null) {
      emit(_cachedState!);
    }

    emit(TripLoading());

    debugPrint('Loading trip data...');
    final result = await _getTrip();

    result.fold(
      (failure) {
        debugPrint('Trip loading failed: ${failure.message}');
        emit(TripError(failure.message));
      },
      (trip) {
        debugPrint('Trip loaded successfully');
        if (trip.id != null) {
          _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(trip.id!));
        }
        _updateTimelineBloc.add(LoadLocalTripUpdatesEvent(trip.id!));

       final newState = TripLoaded(
        trip: trip,
        customerState: _deliveryDataBloc.state,
        timelineState: _updateTimelineBloc.state,
        deliveryDataState: _deliveryDataBloc.state,
      );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onSearchTrip(
    SearchTripEvent event,
    Emitter<TripState> emit,
  ) async {
    emit(TripSearching());

    if (event.clearSearchResults) {
      emit(TripInitial());
      return;
    }

    final result = await _searchTrip(event.tripNumberId);

    result.fold(
      (failure) => emit(TripError(failure.message, isSearchError: true)),
      (trip) {
        debugPrint('🔍 Found trip with ID: ${trip.id}');
        if (trip.id != null) {
          _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(trip.id!));
          _updateTimelineBloc.add(LoadLocalTripUpdatesEvent(trip.id!));

          emit(TripSearchResult(trip: trip, found: true));
          final newState = TripLoaded(
        trip: trip,
        customerState: _deliveryDataBloc.state,
        timelineState: _updateTimelineBloc.state,
        deliveryDataState: _deliveryDataBloc.state,
      );
          _cachedState = newState;
          emit(newState);
        } else {
          emit(const TripError('Invalid trip data: Missing ID'));
        }
      },
    );
  }

  Future<void> _onAcceptTrip(
    AcceptTripEvent event,
    Emitter<TripState> emit,
  ) async {
    emit(TripAccepting());
    debugPrint(
      '🔄 BLOC: Starting trip acceptance process for ID: ${event.tripId}',
    );

    final result = await _acceptTrip(event.tripId);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Trip acceptance failed: ${failure.message}');
        emit(TripError(failure.message));
      },
      (tripData) {
        final (trip, trackingId) = tripData;
        debugPrint('✅ BLOC: Trip accepted successfully');
        debugPrint('   📋 Trip ID: ${trip.id}');
        debugPrint('   🔢 Trip Number: ${trip.tripNumberId}');
        debugPrint('   🎯 Tracking ID: $trackingId');
        debugPrint('   👥 Customers: ${trip.deliveryData.length}');
        debugPrint('   🚛 Delivery Team: ${trip.deliveryTeam.target?.id}');

        // Clear any cached states
        _cachedState = null;

        // // Trigger customer and timeline data loading
        // if (trip.id != null) {
        //   _customerBloc.add(GetCustomerEvent(trip.id!));
        // }
        // _updateTimelineBloc.add(LoadUpdateTimelineEvent());

        emit(
          TripAccepted(
            trip: trip,
            trackingId: trackingId,
            tripId: event.tripId,
          ),
        );
      },
    );
  }

  Future<void> _onCheckEndTripOtpStatus(
    CheckEndTripOtpStatusEvent event,
    Emitter<TripState> emit,
  ) async {
    debugPrint('🔍 Checking end trip OTP status for trip: ${event.tripId}');

    final result = await _checkEndTripStatus();

    result.fold(
      (failure) {
        debugPrint('❌ Failed to check end trip OTP status: ${failure.message}');
        emit(TripError(failure.message));
      },
      (hasEndTripOtp) {
        debugPrint('✅ End trip OTP status checked: $hasEndTripOtp');
        emit(EndTripOtpStatusChecked(hasEndTripOtp));
      },
    );
  }

  Future<void> _onCalculateTripDistance(
    CalculateTripDistanceEvent event,
    Emitter<TripState> emit,
  ) async {
    emit(TripLoading());

    final result = await _calculateTotalTripDistance(event.tripId);

    result.fold(
      (failure) => emit(TripError(failure.message)),
      (totalDistance) => emit(TripDistanceCalculated(totalDistance)),
    );
  }

  Future<void> _onEndTrip(EndTripEvent event, Emitter<TripState> emit) async {
    debugPrint('🔄 BLOC: Starting trip end process for ID: ${event.tripId}');
    emit(TripLoading());

    final result = await _endTrip(event.tripId);

    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Trip end failed: ${failure.message}');
        emit(TripError(failure.message));
      },
      (trip) {
        debugPrint('✅ BLOC: Trip ended successfully');
        debugPrint('   📋 Trip ID: ${trip.id}');
        debugPrint('   🔢 Trip Number: ${trip.tripNumberId}');
        debugPrint('   ⏰ End Time: ${trip.timeEndTrip}');

        // Clear any cached states
        _cachedState = null;

        // Stop location tracking if it's active
        add(const StopLocationTrackingEvent());

        // Explicitly clear local data and reset state
        emit(TripEnded(trip));

        // After a short delay, reset to initial state
        Future.delayed(const Duration(seconds: 2), () {
          if (!isClosed) {
            // Clear any cached trip data from shared preferences
            _clearTripDataFromPreferences();
            add(const GetTripEvent());
          }
        });
      },
    );
  }

  // Helper method to clear trip data from shared preferences
  Future<void> _clearTripDataFromPreferences() async {
    try {
      debugPrint('🧹 BLOC: Clearing trip data from preferences');
      final prefs = await SharedPreferences.getInstance();

      // Get current user data
      final userData = prefs.getString('user_data');
      if (userData != null) {
        final userJson = jsonDecode(userData);

        // Remove trip-related fields
        userJson['tripNumberId'] = null;
        userJson['trip'] = null;

        // Save updated user data
        await prefs.setString('user_data', jsonEncode(userJson));
      }

      // Remove other trip-related preferences
      await prefs.remove('user_trip_data');
      await prefs.remove('trip_cache');
      await prefs.remove('delivery_status_cache');
      await prefs.remove('customer_cache');
      await prefs.remove('active_trip');
      await prefs.remove('last_trip_id');
      await prefs.remove('last_trip_number');

      debugPrint('✅ BLOC: Successfully cleared trip data from preferences');
    } catch (e) {
      debugPrint('❌ BLOC: Error clearing trip data from preferences: $e');
    }
  }

  Future<void> _onUpdateTripLocation(
    UpdateTripLocationEvent event,
    Emitter<TripState> emit,
  ) async {
    debugPrint('🔄 BLOC: Updating trip location for ID: ${event.tripId}');
    debugPrint(
      '📍 Coordinates: Lat: ${event.latitude}, Long: ${event.longitude}',
    );

    emit(TripLocationUpdating());

    final params = UpdateTripLocationParams(
      tripId: event.tripId,
      latitude: event.latitude,
      longitude: event.longitude,
    );

    final result = await _updateTripLocation(params);

    result.fold(
      (failure) {
        debugPrint(
          '❌ BLOC: Failed to update trip location: ${failure.message}',
        );
        emit(LocationTrackingError(failure.message));
      },
      (trip) {
        debugPrint('✅ BLOC: Trip location updated successfully');
        emit(
          TripLocationUpdated(
            trip: trip,
            latitude: event.latitude,
            longitude: event.longitude,
          ),
        );
      },
    );
  }

  Future<void> _onStartLocationTracking(
    StartLocationTrackingEvent event,
    Emitter<TripState> emit,
  ) async {
    debugPrint('🔄 BLOC: Starting location tracking for trip: ${event.tripId}');

    // Stop any existing tracking
    await _stopTracking();

    try {
      // Check if location services are enabled and permissions are granted
      bool serviceEnabled = await LocationService.enableLocationService();
      if (!serviceEnabled) {
        debugPrint('❌ BLOC: Location services are disabled');
        emit(const LocationTrackingError('Location services are disabled'));
        return;
      }

      bool permissionGranted = await LocationService.requestPermission();
      if (!permissionGranted) {
        debugPrint('❌ BLOC: Location permissions are denied');
        emit(const LocationTrackingError('Location permissions are denied'));
        return;
      }

      // Store the trip ID being tracked
      _trackedTripId = event.tripId;

      // Get initial position and update trip
      final initialPosition = await LocationService.getCurrentLocation();

      add(
        UpdateTripLocationEvent(
          tripId: event.tripId,
          latitude: initialPosition.latitude,
          longitude: initialPosition.longitude,
        ),
      );

      // Start tracking distance using LocationService
      _locationSubscription = LocationService.trackDistance().listen((
        distance,
      ) async {
        // When distance is updated, get current position and update trip location
        try {
          final position = await LocationService.getCurrentLocation();

          if (_trackedTripId == event.tripId) {
            add(
              UpdateTripLocationEvent(
                tripId: event.tripId,
                latitude: position.latitude,
                longitude: position.longitude,
              ),
            );

            debugPrint(
              '📍 Updated location - Distance traveled: ${distance.toStringAsFixed(2)} km',
            );
          }
        } catch (e) {
          debugPrint('❌ Error getting current location: $e');
        }
      });

      emit(
        LocationTrackingStarted(
          tripId: event.tripId,
          updateInterval: const Duration(
            minutes: 5,
          ), // Using default from LocationService
          distanceFilter: 1000.0, // Using default from LocationService
        ),
      );

      debugPrint('✅ BLOC: Location tracking started successfully');
    } catch (e) {
      debugPrint('❌ BLOC: Error starting location tracking: $e');
      emit(LocationTrackingError('Error starting location tracking: $e'));
    }
  }

  Future<void> _onStopLocationTracking(
    StopLocationTrackingEvent event,
    Emitter<TripState> emit,
  ) async {
    debugPrint('🔄 BLOC: Stopping location tracking');

    await _stopTracking();

    emit(const LocationTrackingStopped());

    debugPrint('✅ BLOC: Location tracking stopped successfully');
  }

  // Helper method to stop tracking
  Future<void> _stopTracking() async {
    _trackedTripId = null;
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    LocationService.stopTracking();
  }

  void _onClearSearch(ClearTripSearchEvent event, Emitter<TripState> emit) {
    _cachedState = null;
    emit(TripInitial());
    add(const GetTripEvent());
  }

  @override
  Future<void> close() {
    _cachedState = null;
    _stopTracking();
    return super.close();
  }
}
