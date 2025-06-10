import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/create_cancelled_invoice_by_delivery_data_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/delete_cancelled_invoice.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/load_cancelled_invoice_by_id.dart' show LoadCancelledInvoiceById;
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_state.dart';

import '../../domain/usecases/load_cancelled_invoice_by_trip_id.dart';

class CancelledInvoiceBloc extends Bloc<CancelledInvoiceEvent, CancelledInvoiceState> {
  final LoadCancelledInvoicesByTripId _loadCancelledInvoicesByTripId;
  final LoadCancelledInvoiceById _loadCancelledInvoicesById;
  final CreateCancelledInvoiceByDeliveryDataId _createCancelledInvoiceByDeliveryDataId;
  final DeleteCancelledInvoice _deleteCancelledInvoice;

  CancelledInvoiceBloc({
    required LoadCancelledInvoicesByTripId loadCancelledInvoicesByTripId,
    required LoadCancelledInvoiceById loadCancelledInvoicesById,
    required CreateCancelledInvoiceByDeliveryDataId createCancelledInvoiceByDeliveryDataId,
    required DeleteCancelledInvoice deleteCancelledInvoice,
  }) : _loadCancelledInvoicesByTripId = loadCancelledInvoicesByTripId,
       _loadCancelledInvoicesById = loadCancelledInvoicesById,
       _createCancelledInvoiceByDeliveryDataId = createCancelledInvoiceByDeliveryDataId,
       _deleteCancelledInvoice = deleteCancelledInvoice,
       super(const CancelledInvoiceInitial()) {
    
    on<LoadCancelledInvoicesByTripIdEvent>(_onLoadCancelledInvoicesByTripId);
    on<LoadLocalCancelledInvoicesByTripIdEvent>(_onLoadLocalCancelledInvoicesByTripId);
    on<LoadCancelledInvoicesByIdEvent>(_onLoadCancelledInvoicesById);
    on<LoadLocalCancelledInvoicesByIdEvent>(_onLoadLocalCancelledInvoicesById);
    on<CreateCancelledInvoiceByDeliveryDataIdEvent>(_onCreateCancelledInvoiceByDeliveryDataId);
    on<DeleteCancelledInvoiceEvent>(_onDeleteCancelledInvoice);
  }

  Future<void> _onLoadCancelledInvoicesByTripId(
    LoadCancelledInvoicesByTripIdEvent event,
    Emitter<CancelledInvoiceState> emit,
  ) async {
    emit(const CancelledInvoiceLoading());
    debugPrint('🔄 BLoC: Loading cancelled invoices for trip: ${event.tripId}');

    final result = await _loadCancelledInvoicesByTripId(event.tripId);
    
    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to load cancelled invoices: ${failure.message}');
        emit(CancelledInvoiceError(failure.message));
      },
      (cancelledInvoices) {
        debugPrint('✅ BLoC: Loaded ${cancelledInvoices.length} cancelled invoices');
        emit(CancelledInvoicesLoaded(cancelledInvoices));
      },
    );
  }

  Future<void> _onLoadLocalCancelledInvoicesByTripId(
    LoadLocalCancelledInvoicesByTripIdEvent event,
    Emitter<CancelledInvoiceState> emit,
  ) async {
    emit(const CancelledInvoiceLoading());
    debugPrint('📱 BLoC: Loading local cancelled invoices for trip: ${event.tripId}');

    final result = await _loadCancelledInvoicesByTripId.loadFromLocal(event.tripId);
    
    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to load local cancelled invoices: ${failure.message}');
        emit(CancelledInvoiceError(failure.message));
      },
      (cancelledInvoices) {
        debugPrint('✅ BLoC: Loaded ${cancelledInvoices.length} local cancelled invoices');
        emit(CancelledInvoicesLoaded(cancelledInvoices));
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
}
