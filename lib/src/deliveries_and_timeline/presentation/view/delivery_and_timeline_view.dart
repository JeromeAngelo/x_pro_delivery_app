import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/screens/delivery_list_screen.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/screens/update_timeline_view.dart';

class DeliveryAndTimeline extends StatefulWidget {
  const DeliveryAndTimeline({super.key});

  @override
  State<DeliveryAndTimeline> createState() => _DeliveryAndTimelineState();
}

class _DeliveryAndTimelineState extends State<DeliveryAndTimeline>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AuthBloc _authBloc;
  late final DeliveryDataBloc _customerBloc;
  late final TripUpdatesBloc _tripUpdatesBloc;
  bool _isInitialized = false;
  DeliveryDataState? _cachedCustomerState;
  TripUpdatesState? _cachedUpdatesState;
  StreamSubscription? _authSubscription;
  String _tripTitle = 'Loading...';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeBlocs();
    _setupDataListeners();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _customerBloc = context.read<DeliveryDataBloc>();
    _tripUpdatesBloc = context.read<TripUpdatesBloc>();
  }

  void _setupDataListeners() {
    if (!_isInitialized) {
      _authSubscription = _authBloc.stream.listen((state) {
        if (state is UserTripLoaded && state.trip.id != null) {
          debugPrint('✅ User trip loaded: ${state.trip.id}');
          _updateTripTitle(state.trip.tripNumberId);
          _loadDataForTrip(state.trip.id!);
        } else if (state is UserByIdLoaded) {
          // Check if user has trip relation
          final user = state.user;
          if (user.trip.target != null) {
            final trip = user.trip.target!;
            debugPrint('✅ User with trip loaded: ${trip.id}');
            _updateTripTitle(trip.tripNumberId);
            _loadDataForTrip(trip.id ?? '');
          } else {
            debugPrint('⚠️ User loaded but no trip assigned');
            _updateTripTitle(null);
          }
        }
      });

      _loadInitialData();
      _isInitialized = true;
    }
  }

  void _updateTripTitle(String? tripNumberId) {
    setState(() {
      _tripTitle = tripNumberId ?? 'No Trip Assigned';
    });
    debugPrint('🏷️ Trip title updated: $_tripTitle');
  }

  Future<void> _loadInitialData() async {
    debugPrint('🚀 DELIVERY: Attempting immediate data load');
    
    // 🔄 Try to get trip ID from SharedPreferences first
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');
    String? tripId;

    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final userId = userData['id'];
      
      // Check for trip data in user data
      if (userData['trip'] != null && userData['trip']['id'] != null) {
        tripId = userData['trip']['id'];
        debugPrint('🎫 Found trip ID in stored data: $tripId');
      } else if (userData['tripNumberId'] != null) {
        tripId = userData['tripNumberId'];
        debugPrint('🎫 Using trip number as ID: $tripId');
      }

      if (userId != null) {
        debugPrint('🔄 Loading user trip data for ID: $userId');
        // 📱 OFFLINE-FIRST: Load local data immediately
        _authBloc.add(LoadLocalUserTripEvent(userId));
        
        // 🌐 Then attempt remote if online
        if (mounted) {
          final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
          if (connectivity.isOnline) {
            debugPrint('🌐 Online: Syncing fresh trip data');
            _authBloc.add(GetUserTripEvent(userId));
          } else {
            debugPrint('📱 Offline: Using cached trip data only');
          }
        }
      }
    } else {
      debugPrint('⚠️ DELIVERY: No trip ID found in SharedPreferences');
    }

    // If we have a trip ID from storage, load its data immediately
    if (tripId != null) {
      debugPrint('📦 Loading cached delivery data for trip: $tripId');
      _loadDataForTrip(tripId);
    }
  }

  void _loadDataForTrip(String tripId) {
    debugPrint('📱 Loading data for trip: $tripId');

    // 📱 OFFLINE-FIRST: Load local data immediately
    _customerBloc.add(GetLocalDeliveryDataByTripIdEvent(tripId));
    _tripUpdatesBloc.add(LoadLocalTripUpdatesEvent(tripId));

    // 🌐 Then sync remote data if online
    if (mounted) {
      final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
      if (connectivity.isOnline) {
        debugPrint('🌐 Online: Syncing fresh delivery and timeline data');
        _customerBloc.add(GetDeliveryDataByTripIdEvent(tripId));
        _tripUpdatesBloc.add(GetTripUpdatesEvent(tripId));
      } else {
        debugPrint('📱 Offline: Using cached delivery and timeline data only');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DeliveryDataBloc, DeliveryDataState>(
          listener: (context, state) {
            if (state is AllDeliveryDataLoaded) {
              setState(() => _cachedCustomerState = state);
            }
          },
        ),
        BlocListener<TripUpdatesBloc, TripUpdatesState>(
          listener: (context, state) {
            if (state is TripUpdatesLoaded) {
              setState(() => _cachedUpdatesState = state);
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is UserTripLoaded) {
              final trip = state.trip;
              _updateTripTitle(trip.tripNumberId);
            } else if (state is UserByIdLoaded) {
              final user = state.user;
              final tripNumberId = user.trip.target?.tripNumberId;
              _updateTripTitle(tripNumberId);
            }
          },
        ),
      ],
      child: BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
        builder: (context, state) {
          debugPrint('🎯 Building DeliveryAndTimeline with state: $state');
          debugPrint('🏷️ Current trip title: $_tripTitle');

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/homepage'),
              ),
              title: Text(_tripTitle),
              centerTitle: true,
              bottom: TabBar(
                labelColor: Theme.of(context).colorScheme.onSurface,
                controller: _tabController,
                tabs: [
                  Tab(
                    text: 'Deliveries',
                    icon: Icon(
                      Icons.local_shipping,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Tab(
                    text: 'Updates',
                    icon: Icon(
                      Icons.update,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // In the build method, update the TabBarView section:
            body: TabBarView(
              controller: _tabController,
              children: [
                const DeliveryListScreen(),
                // Pass the tripId to UpdateTimelineView
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    String? tripId;

                    if (state is UserTripLoaded) {
                      tripId = state.trip.id;
                    } else if (state is UserByIdLoaded) {
                      tripId = state.user.trip.target?.id;
                    }

                    if (tripId != null) {
                      return UpdateTimelineView(tripId: tripId);
                    } else {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No trip assigned',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please contact your administrator',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }
}
