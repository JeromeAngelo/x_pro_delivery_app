import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/common/mixins/offline_first_mixin.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/create_cancelled_invoice_by_delivery_data_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/delete_cancelled_invoice.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/load_cancelled_invoice_by_id.dart' show LoadCancelledInvoiceById;
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_state.dart';

import '../../domain/usecases/load_cancelled_invoice_by_trip_id.dart';

class CancelledInvoiceBloc extends Bloc<CancelledInvoiceEvent, CancelledInvoiceState> with OfflineFirstMixin<CancelledInvoiceEvent, CancelledInvoiceState> {
  final LoadCancelledInvoicesByTripId _loadCancelledInvoicesByTripId;
  final LoadCancelledInvoiceById _loadCancelledInvoicesById;
  final CreateCancelledInvoiceByDeliveryDataId _createCancelledInvoiceByDeliveryDataId;
  final DeleteCancelledInvoice _deleteCancelledInvoice;
  final ConnectivityProvider _connectivity;

  CancelledInvoiceBloc({
    required LoadCancelledInvoicesByTripId loadCancelledInvoicesByTripId,
    required LoadCancelledInvoiceById loadCancelledInvoicesById,
    required CreateCancelledInvoiceByDeliveryDataId createCancelledInvoiceByDeliveryDataId,
    required DeleteCancelledInvoice deleteCancelledInvoice,
    required ConnectivityProvider connectivity,
  }) : _loadCancelledInvoicesByTripId = loadCancelledInvoicesByTripId,
       _loadCancelledInvoicesById = loadCancelledInvoicesById,
       _createCancelledInvoiceByDeliveryDataId = createCancelledInvoiceByDeliveryDataId,
       _deleteCancelledInvoice = deleteCancelledInvoice,
       _connectivity = connectivity,
       super(const CancelledInvoiceInitial()) {
    
    on<LoadCancelledInvoicesByTripIdEvent>(_onLoadCancelledInvoicesByTripId);
    on<LoadLocalCancelledInvoicesByTripIdEvent>(_onLoadLocalCancelledInvoicesByTripId);
    on<LoadCancelledInvoicesByIdEvent>(_onLoadCancelledInvoicesById);
    on<LoadLocalCancelledInvoicesByIdEvent>(_onLoadLocalCancelledInvoicesById);
    on<CreateCancelledInvoiceByDeliveryDataIdEvent>(_onCreateCancelledInvoiceByDeliveryDataId);
    on<DeleteCancelledInvoiceEvent>(_onDeleteCancelledInvoice);
    on<RefreshCancelledInvoicesEvent>(_onRefreshCancelledInvoices);
  }

  Future<void> _onLoadCancelledInvoicesByTripId(
    LoadCancelledInvoicesByTripIdEvent event,
    Emitter<CancelledInvoiceState> emit,
  ) async {
    debugPrint('🔍 OFFLINE-FIRST: Loading cancelled invoices for trip: ${event.tripId}');
    emit(const CancelledInvoiceLoading());

    await executeOfflineFirst(
      localOperation: () async {
        final result = await _loadCancelledInvoicesByTripId.loadFromLocal(event.tripId);
        result.fold(
          (failure) => throw Exception(failure.message),
          (cancelledInvoices) {
            if (cancelledInvoices.isEmpty) {
              emit(CancelledInvoicesEmpty(event.tripId));
            } else {
              emit(CancelledInvoicesOffline(
                cancelledInvoices: cancelledInvoices,
                message: 'Showing offline data',
              ));
            }
          },
        );
      },
      remoteOperation: () async {
        final result = await _loadCancelledInvoicesByTripId(event.tripId);
        result.fold(
          (failure) => throw Exception(failure.message),
          (cancelledInvoices) {
            emit(CancelledInvoicesLoaded(cancelledInvoices));
          },
        );
      },
      onLocalSuccess: (data) {
        debugPrint('✅ Cancelled invoices loaded from local cache');
      },
      onRemoteSuccess: (data) {
        debugPrint('✅ Cancelled invoices synced from remote');
      },
      onError: (error) => emit(CancelledInvoiceError(error)),
      connectivity: _connectivity,
    );
  }

  /// Legacy method - use LoadCancelledInvoicesByTripIdEvent with offline-first pattern instead
  Future<void> _onLoadLocalCancelledInvoicesByTripId(
    LoadLocalCancelledInvoicesByTripIdEvent event,
    Emitter<CancelledInvoiceState> emit,
  ) async {
    // Only emit loading state if we don't have any data
    if (state is CancelledInvoiceInitial) {
      emit(const CancelledInvoiceLoading());
    }
    
    debugPrint('📱 BLoC: Loading local cancelled invoices for trip: ${event.tripId}');

    final result = await _loadCancelledInvoicesByTripId.loadFromLocal(event.tripId);
    
    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to load local cancelled invoices: ${failure.message}');
        // Only emit error if we don't have any existing data
        if (state is CancelledInvoiceInitial || state is CancelledInvoiceLoading) {
          emit(CancelledInvoiceError(failure.message));
        }
      },
      (cancelledInvoices) {
        debugPrint('✅ BLoC: Loaded ${cancelledInvoices.length} local cancelled invoices');
        if (cancelledInvoices.isEmpty) {
          // Only emit empty if we don't have existing data
          if (state is CancelledInvoiceInitial || state is CancelledInvoiceLoading) {
            emit(CancelledInvoicesEmpty(event.tripId));
          }
        } else {
          emit(CancelledInvoicesOffline(
            cancelledInvoices: cancelledInvoices,
            message: 'Showing offline data',
          ));
        }
      },
    );
  }

  Future<void> _onLoadCancelledInvoicesById(
    LoadCancelledInvoicesByIdEvent event,
    Emitter<CancelledInvoiceState> emit,
  ) async {
    emit(const CancelledInvoiceLoading());
    debugPrint('🔄 BLoC: Loading cancelled invoice by ID: ${event.id}');

    final result = await _loadCancelledInvoicesById(event.id);
    
    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to load cancelled invoice by ID: ${failure.message}');
        emit(CancelledInvoiceError(failure.message));
      },
      (cancelledInvoices) {
        debugPrint('✅ BLoC: Loaded cancelled invoice by ID');
        emit(SpecificCancelledInvoiceLoaded(cancelledInvoices));
      },
    );
  }

  Future<void> _onLoadLocalCancelledInvoicesById(
    LoadLocalCancelledInvoicesByIdEvent event,
    Emitter<CancelledInvoiceState> emit,
  ) async {
    emit(const CancelledInvoiceLoading());
    debugPrint('📱 BLoC: Loading local cancelled invoice by ID: ${event.id}');

    final result = await _loadCancelledInvoicesById.loadFromLocal(event.id);
    
    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to load local cancelled invoice by ID: ${failure.message}');
        emit(CancelledInvoiceError(failure.message));
      },
      (cancelledInvoices) {
        debugPrint('✅ BLoC: Loaded local cancelled invoice by ID');
        emit(SpecificCancelledInvoiceLoaded(cancelledInvoices));
      },
    );
  }

    Future<void> _onCreateCancelledInvoiceByDeliveryDataId(
    CreateCancelledInvoiceByDeliveryDataIdEvent event,
    Emitter<CancelledInvoiceState> emit,
  ) async {
    emit(const CancelledInvoiceLoading());
    debugPrint('🔄 BLoC: Creating cancelled invoice for delivery data: ${event.deliveryDataId}');
    debugPrint('📝 BLoC: Reason: ${event.reason.toString().split('.').last}');

    final result = await _createCancelledInvoiceByDeliveryDataId(
      CreateCancelledInvoiceParams(
        deliveryDataId: event.deliveryDataId,
        reason: event.reason,
        image: event.image,
      ),
    );
    
    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to create cancelled invoice: ${failure.message}');
        emit(CancelledInvoiceError(failure.message));
      },
      (cancelledInvoice) {
        debugPrint('✅ BLoC: Successfully created cancelled invoice: ${cancelledInvoice.id}');
        emit(CancelledInvoiceCreated(cancelledInvoice));
      },
    );
  }


  Future<void> _onDeleteCancelledInvoice(
    DeleteCancelledInvoiceEvent event,
    Emitter<CancelledInvoiceState> emit,
  ) async {
    emit(const CancelledInvoiceLoading());
    debugPrint('🗑️ BLoC: Deleting cancelled invoice: ${event.cancelledInvoiceId}');

    final result = await _deleteCancelledInvoice(event.cancelledInvoiceId);
    
    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to delete cancelled invoice: ${failure.message}');
        emit(CancelledInvoiceError(failure.message));
      },
      (success) {
        if (success) {
          debugPrint('✅ BLoC: Successfully deleted cancelled invoice');
          emit(CancelledInvoiceDeleted(event.cancelledInvoiceId));
        } else {
          debugPrint('❌ BLoC: Failed to delete cancelled invoice');
          emit(const CancelledInvoiceError('Failed to delete cancelled invoice'));
        }
      },
    );
  }

  Future<void> _onRefreshCancelledInvoices(
    RefreshCancelledInvoicesEvent event,
    Emitter<CancelledInvoiceState> emit,
  ) async {
    debugPrint('🔄 BLoC: Refreshing cancelled invoices for trip: ${event.tripId}');
    
    // Don't emit loading state for refresh to avoid UI flicker
    final result = await _loadCancelledInvoicesByTripId(event.tripId);

    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Refresh failed: ${failure.message}');
        // Keep current state if refresh fails
        emit(CancelledInvoiceError(failure.message));
      },
      (cancelledInvoices) {
        debugPrint('✅ BLoC: Successfully refreshed ${cancelledInvoices.length} cancelled invoices');
        
        if (cancelledInvoices.isEmpty) {
          emit(CancelledInvoicesEmpty(event.tripId));
        } else {
          emit(CancelledInvoicesLoaded(cancelledInvoices));
        }
      },
    );
  }
}
