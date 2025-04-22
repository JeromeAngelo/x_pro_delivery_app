import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/usecase/get_completed_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/usecase/get_completed_customer_by_id_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_event.dart';

class CompletedCustomerBloc
    extends Bloc<CompletedCustomerEvent, CompletedCustomerState> {
  final GetCompletedCustomer _getCompletedCustomers;
  final GetCompletedCustomerById _getCompletedCustomerById;
  CompletedCustomerState? _cachedState;
  final InvoiceBloc _invoiceBloc;

  CompletedCustomerBloc({
    required InvoiceBloc invoiceBloc,
    required GetCompletedCustomer getCompletedCustomers,
    required GetCompletedCustomerById getCompletedCustomerById,
  }) : _getCompletedCustomers = getCompletedCustomers,
       _getCompletedCustomerById = getCompletedCustomerById,
       _invoiceBloc = invoiceBloc,
       super(const CompletedCustomerInitial()) {
    on<GetCompletedCustomerEvent>(_getCompletedCustomerHandler);
    on<GetCompletedCustomerByIdEvent>(_getCompletedCustomerByIdHandler);
    on<LoadLocalCompletedCustomerEvent>(_onLoadLocalCompletedCustomers);
    on<LoadLocalCompletedCustomerByIdEvent>(_onLoadLocalCompletedCustomerById);
    on<ClearCompletedCustomerCacheEvent>(_onClearCache);
  }
  Future<void> _getCompletedCustomerHandler(
    GetCompletedCustomerEvent event,
    Emitter<CompletedCustomerState> emit,
  ) async {
    // Normalize the trip ID if needed
    String tripId = event.tripId;
    if (tripId.startsWith('{')) {
      final tripData = jsonDecode(tripId);
      tripId = tripData['id'];
      debugPrint('🔄 Normalized trip ID: $tripId');
    }

    // If we have cached data, emit it first for immediate UI update
    if (_cachedState != null && _cachedState is CompletedCustomerLoaded) {
      emit(_cachedState!);
    } else {
      emit(const CompletedCustomerLoading());
    }

    // Fetch data
    final result = await _getCompletedCustomers(tripId);
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load completed customers: ${failure.message}');
        emit(CompletedCustomerError(failure.message));
      },
      (customers) {
        debugPrint('✅ Loaded ${customers.length} completed customers');

        // Fetch related invoice data
        _invoiceBloc.add(const GetInvoiceEvent());

        final newState = CompletedCustomerLoaded(
          customers: customers,
          invoice: _invoiceBloc.state,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _getCompletedCustomerByIdHandler(
    GetCompletedCustomerByIdEvent event,
    Emitter<CompletedCustomerState> emit,
  ) async {
    emit(const CompletedCustomerLoading());
    final result = await _getCompletedCustomerById(event.customerId);
    result.fold(
      (failure) => emit(CompletedCustomerError(failure.message)),
      (customer) => emit(CompletedCustomerByIdLoaded(customer)),
    );
  }

  Future<void> _onLoadLocalCompletedCustomers(
    LoadLocalCompletedCustomerEvent event,
    Emitter<CompletedCustomerState> emit,
  ) async {
    debugPrint(
      '📱 Loading local completed customers for trip: ${event.tripId}',
    );
    emit(const CompletedCustomerLoading());

    // Normalize the trip ID if needed
    String tripId = event.tripId;
    if (tripId.startsWith('{')) {
      final tripData = jsonDecode(tripId);
      tripId = tripData['id'];
      debugPrint('🔄 Normalized trip ID: $tripId');
    }

    final result = await _getCompletedCustomers.loadFromLocal(tripId);

    result.fold(
      (failure) {
        debugPrint('⚠️ Local load failed: ${failure.message}');
        // If local load fails, try remote
        add(GetCompletedCustomerEvent(tripId));
      },
      (customers) {
        if (customers.isEmpty) {
          debugPrint('📭 No local data found, syncing from remote');
          add(GetCompletedCustomerEvent(tripId));
        } else {
          debugPrint(
            '✅ Loaded ${customers.length} completed customers from local storage',
          );
          _invoiceBloc.add(const GetInvoiceEvent());

          final newState = CompletedCustomerLoaded(
            customers: customers,
            invoice: _invoiceBloc.state,
            isFromLocal: true,
          );
          _cachedState = newState;
          emit(newState);

          // Background sync
          add(GetCompletedCustomerEvent(tripId));
        }
      },
    );
  }

  Future<void> _onLoadLocalCompletedCustomerById(
    LoadLocalCompletedCustomerByIdEvent event,
    Emitter<CompletedCustomerState> emit,
  ) async {
    debugPrint(
      '📱 Loading local completed customer by ID: ${event.customerId}',
    );
    emit(const CompletedCustomerLoading());

    final result = await _getCompletedCustomerById.loadFromLocal(
      event.customerId,
    );
    result.fold(
      (failure) {
        debugPrint('⚠️ Local fetch failed: ${failure.message}');
        emit(CompletedCustomerError(failure.message));
      },
      (customer) {
        debugPrint('✅ Found completed customer: ${customer.storeName}');
        debugPrint('   📦 Updates: ${customer.deliveryStatus.length}');
        debugPrint('   🧾 Invoices: ${customer.invoices.length}');
        emit(CompletedCustomerByIdLoaded(customer));
      },
    );
  }

  // Add this method
  Future<void> _onClearCache(
    ClearCompletedCustomerCacheEvent event,
    Emitter<CompletedCustomerState> emit,
  ) async {
    debugPrint('🧹 Clearing completed customer cache');
    _cachedState = null;
    emit(const CompletedCustomerInitial());
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
