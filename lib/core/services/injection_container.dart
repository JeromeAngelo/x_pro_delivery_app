import 'package:get_it/get_it.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/update_delivery_location.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_items/data/model/return_items_model.dart'
    show ReturnItemsModel;
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/data/repo/logs_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/repo/logs_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/presentation/bloc/logs_bloc.dart';
import 'package:x_pro_delivery_app/core/services/app_logger.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/datasource/local_datasource/delivery_team_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/datasource/remote_datasource/delivery_team_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/repo/delivery_team_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/repo/delivery_team_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/usecase/assign_delivery_team_to_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/usecase/load_delivery_team.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/usecase/load_delivery_team_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/datasource/local_datasource/personel_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/datasource/remote_datasource/personel_remote_data_source.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/repo/personels_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/repo/personal_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/usecase/get_personels.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/usecase/load_personels_by_delivery_team.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/usecase/load_personels_by_trip_Id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/usecase/set_role.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/presentation/bloc/personel_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/data/datasource/local_datasource/vehicle_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/data/datasource/remote_datasource/vehicle_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/data/model/vehicle_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/data/repo/vehicle_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/domain/repo/vehicle_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/domain/usecase/get_vehicle.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/domain/usecase/load_vehicle_by_delivery_team_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/domain/usecase/load_vehicle_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/presentation/bloc/vehicle_bloc.dart';

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/datasource/remote_datasource/delivery_update_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/datasource/local_datasource/delivery_update_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/repo/delivery_update_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/repo/delivery_update_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/check_end_delivery_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/complete_delivery_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/create_delivery_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/get_delivery_update.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/itialized_pending_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/update_delivery_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/update_queue_remarks.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/datasource/local_datasource/trip_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/datasource/remote_datasource/trip_remote_datasurce.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/repo/trip_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/repo/trip_repo.dart';
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
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/datasources/local_datasource/trip_update_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/datasources/remote_datasource/trip_update_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/repo/trip_update_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/repo/trip_update_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/usecases/create_trip_updates.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/usecases/get_trip_updates.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/data_source/local_datasource/update_timeline_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/data_source/remote_datasource/update_timeline_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/models/update_timeline_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/data/repo/update_timeline_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/repo/update_timeline_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/usecase/load_update_timeline.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/usecase/set_update_timeline.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/presentation/bloc/update_timeline_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/datasource/local_datasource/checklist_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/datasource/remote_datasource/checklist_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/repo/checklist_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/repo/checklist_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/usecase/check_Item.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/usecase/load_Checklist.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/usecase/load_checklist_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/presentation/bloc/checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/data/datasources/local_datasource/end_trip_checklist_local_data_src.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/data/datasources/remote_datasource/end_trip_checklist_remote_data_src.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/data/repo/end_trip_checklist_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/repo/end_trip_checklist_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/usecase/check_end_trip_checklist.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/usecase/generate_end_trip_checklist.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/usecase/load_end_trip_checklist.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/data/datasources/local_datasource/end_trip_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/data/datasources/remote_datasource/end_trip_otp_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/data/repo/end_trip_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/domain/repo/end_trip_otp_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/domain/usecases/end_otp_verify.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/domain/usecases/get_end_trip_generated.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/domain/usecases/load_end_trip_otp_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/domain/usecases/load_end_trip_otp_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/presentation/bloc/end_trip_otp_bloc.dart';

import 'package:x_pro_delivery_app/core/common/app/features/otp/data/datasource/local_datasource/otp_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/data/datasource/remote_data_source/otp_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/data/models/otp_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/data/repo/otp_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/repo/otp_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/usecases/get_generated_otp.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/usecases/load_otp_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/usecases/load_otp_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/usecases/verify_in_transit.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/usecases/veryfy_in_end_delivery.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/presentation/bloc/otp_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/load_cancelled_invoice_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_bloc.dart'
    show CancelledInvoiceBloc;
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/data/datasources/remote_datasource/customer_data_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/data/repo/customer_data_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/repo/customer_data_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/add_customer_to_delivery.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/create_customer_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/delete_all_customer_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/delete_customer_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/get_all_customer_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/get_customer_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/get_customer_data_by_delivery_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/usecases/update_customer_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/presentation/bloc/customer_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/repo/delivery_data_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/repo/delivery_data_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/calculate_delivery_time_by_delivery_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/delete_delivery_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/get_all_delivery_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/get_delivery_data_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/get_delivery_data_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/data/datasource/remote_datasource/delivery_receipt_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/data/repo/delivery_receipt_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/domain/repo/delivery_receipt_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/domain/usecases/create_delivery_receipt.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/domain/usecases/delete_delivery_receipt.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/domain/usecases/generate_pdf.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/domain/usecases/get_delivery_receipt_by_delivery_data_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/domain/usecases/get_delivery_receipt_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/presentation/bloc/delivery_receipt_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/data/datasource/remote_datasource/delivery_vehicle_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/data/repo/delivery_vehicle_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/repo/delivery_vehicle_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/usecases/load_all_delivery_vehicle.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/usecases/load_delivery_vehicle_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/usecases/load_delivery_vehicle_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/data/datasources/remote_datasource/invoice_data_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/data/repo/invoice_data_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/domain/repo/invoice_data_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/domain/usecase/add_invoice_data_to_delivery.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/domain/usecase/add_invoice_data_to_invoice_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/domain/usecase/get_all_invoice_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/domain/usecase/get_invoice_data_by_customer_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/domain/usecase/get_invoice_data_by_delivery_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/domain/usecase/get_invoice_data_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/data/datasource/local_datasource/invoice_items_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/data/datasource/remote_datasource/invoice_items_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/data/model/invoice_items_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/data/repo/invoice_items_repo_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/domain/repo/invoice_items_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/domain/usecases/get_all_invoice_items.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/domain/usecases/get_invoice_item_by_invoice_data_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/domain/usecases/update_invoice_item_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/presentation/bloc/invoice_items_bloc.dart';

import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
import 'package:x_pro_delivery_app/core/services/objectbox.dart';
import 'package:x_pro_delivery_app/core/services/sync_service.dart';
import 'package:x_pro_delivery_app/src/auth/data/datasources/local_datasource/auth_local_data_source.dart';
import 'package:x_pro_delivery_app/src/auth/data/datasources/remote_data_source/auth_remote_data_src.dart';
import 'package:x_pro_delivery_app/src/auth/data/repo/auth_repo_impl.dart';
import 'package:x_pro_delivery_app/src/auth/domain/repo/auth_repo.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/get_user_by_id.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/get_user_trip.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/load_user.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/refresh_data.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/sign_in.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/sync_trip_data.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/sync_user_data.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/on_boarding/data/repo/onboarding_repo_impl.dart';
import 'package:x_pro_delivery_app/src/on_boarding/domain/repo/onboarding_repo.dart';
import 'package:x_pro_delivery_app/src/on_boarding/domain/usecases/cache_firstimer.dart';
import 'package:x_pro_delivery_app/src/on_boarding/domain/usecases/check_if_user_firsttimer.dart';
import 'package:x_pro_delivery_app/src/on_boarding/presentation/bloc/onboarding_bloc.dart';

import '../../src/on_boarding/data/local_datasource/onboarding_local_datasource.dart';
import '../common/app/features/Trip_Ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_datasource.dart'
    show CancelledInvoiceLocalDataSource, CancelledInvoiceLocalDataSourceImpl;
import '../common/app/features/Trip_Ticket/cancelled_invoices/data/datasources/remote_datasource/cancelled_invoice_remote_datasource.dart'
    show CancelledInvoiceRemoteDataSource, CancelledInvoiceRemoteDataSourceImpl;
import '../common/app/features/Trip_Ticket/cancelled_invoices/data/repo/cancelled_invoice_repo_impl.dart'
    show CancelledInvoiceRepoImpl;
import '../common/app/features/Trip_Ticket/cancelled_invoices/domain/repo/cancelled_invoice_repo.dart'
    show CancelledInvoiceRepo;
import '../common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/create_cancelled_invoice_by_delivery_data_id.dart'
    show CreateCancelledInvoiceByDeliveryDataId;
import '../common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/delete_cancelled_invoice.dart'
    show DeleteCancelledInvoice;
import '../common/app/features/Trip_Ticket/cancelled_invoices/domain/usecases/load_cancelled_invoice_by_trip_id.dart'
    show LoadCancelledInvoicesByTripId;

import '../common/app/features/Trip_Ticket/collection/data/datasource/local_datasource/collection_local_datasource.dart';
import '../common/app/features/Trip_Ticket/collection/data/datasource/remote_datasource/collection_remote_datasource.dart'
    show CollectionRemoteDataSource, CollectionRemoteDataSourceImpl;
import '../common/app/features/Trip_Ticket/collection/data/repo/collection_repo_impl.dart'
    show CollectionRepoImpl;
import '../common/app/features/Trip_Ticket/collection/domain/repo/collection_repo.dart'
    show CollectionRepo;
import '../common/app/features/Trip_Ticket/collection/domain/usecases/delete_collection.dart'
    show DeleteCollection;
import '../common/app/features/Trip_Ticket/collection/domain/usecases/get_collection_by_id.dart';
import '../common/app/features/Trip_Ticket/collection/domain/usecases/get_collection_by_trip_id.dart';
import '../common/app/features/Trip_Ticket/delivery_data/domain/usecases/set_invoice_into_completed.dart';
import '../common/app/features/Trip_Ticket/delivery_data/domain/usecases/set_invoice_into_unloaded.dart';
import '../common/app/features/Trip_Ticket/delivery_data/domain/usecases/set_invoice_into_unloading.dart';
import '../common/app/features/Trip_Ticket/delivery_data/domain/usecases/sync_delivery_data_by_trip_id.dart';
import '../common/app/features/Trip_Ticket/delivery_update/domain/usecase/bulk_update_delivery_status.dart';
import '../common/app/features/Trip_Ticket/delivery_update/domain/usecase/get_bulk_delivery_status_choices.dart';
import '../common/app/features/Trip_Ticket/delivery_update/domain/usecase/pin_arrived_location.dart';
import '../common/app/features/Trip_Ticket/invoice_data/domain/usecase/set_invoice_unloaded.dart';
import '../common/app/features/Trip_Ticket/invoice_status/data/datasources/local_datasource/invoice_status_local_datasource.dart';
import '../common/app/features/Trip_Ticket/invoice_status/data/datasources/remote_datasource/invoice_status_remote_datasource.dart';
import '../common/app/features/Trip_Ticket/invoice_status/data/repo/invoice_status_repo_impl.dart';
import '../common/app/features/Trip_Ticket/invoice_status/domain/repo/invoice_status_repo.dart';
import '../common/app/features/Trip_Ticket/invoice_status/domain/usecase/get_invoice_status_by_invoice_id.dart';
import '../common/app/features/Trip_Ticket/invoice_status/presentation/bloc/invoice_status_bloc.dart';
import '../common/app/features/Trip_Ticket/return_items/data/datasource/local_datasource/return_items_local_datasource.dart';
import '../common/app/features/Trip_Ticket/return_items/data/datasource/remote_datasource/return_items_remote_datasource.dart';
import '../common/app/features/Trip_Ticket/return_items/data/repo/return_items_repo_impl.dart';
import '../common/app/features/Trip_Ticket/return_items/domain/repo/return_items_repo.dart';
import '../common/app/features/Trip_Ticket/return_items/domain/usecases/add_items_to_return_items_by_delivery_id.dart';
import '../common/app/features/Trip_Ticket/return_items/domain/usecases/get_return_items_by_id.dart';
import '../common/app/features/Trip_Ticket/return_items/domain/usecases/get_return_items_by_trip_id.dart';
import '../common/app/features/Trip_Ticket/return_items/presentation/bloc/return_items_bloc.dart';
import '../common/app/features/Trip_Ticket/trip/domain/usecase/check_trip_personnels.dart';
import '../common/app/features/Trip_Ticket/trip/domain/usecase/set_mismatched_reason.dart';
import '../common/app/features/app_logs/data/datasource/local_datasource/logs_local_datasource/logs_local_datasource.dart';
import '../common/app/features/app_logs/domain/usecases/add_log.dart';
import '../common/app/features/app_logs/domain/usecases/clear_logs.dart';
import '../common/app/features/app_logs/domain/usecases/download_logs_pdf.dart';
import '../common/app/features/app_logs/domain/usecases/get_logs.dart'
    show GetLogs;
import '../common/app/features/app_logs/data/datasource/remote_datasource/logs_remote_datasource.dart';
import '../common/app/features/app_logs/domain/usecases/get_unsynced_logs.dart';
import '../common/app/features/app_logs/domain/usecases/mark_logs_as_synced.dart';
import '../common/app/features/app_logs/domain/usecases/sync_logs_to_remote.dart';
import '../common/app/features/sync_data/cubit/sync_cubit.dart';
import '../common/app/features/user_performance/data/datasources/local_datasource/user_performance_local_datasource.dart';
import '../common/app/features/user_performance/data/datasources/remote_datasource/user_performance_remote_datasource.dart';
import '../common/app/features/user_performance/data/model/user_performance_model.dart';
import '../common/app/features/user_performance/data/repo/user_performance_repo_impl.dart';
import '../common/app/features/user_performance/domain/repo/user_performance_repo.dart';
import '../common/app/features/user_performance/domain/usecases/calculate_delivery_accuracy.dart';
import '../common/app/features/user_performance/domain/usecases/load_user_performance_by_user_id.dart';
import '../common/app/features/user_performance/presentation/bloc/user_performance_bloc.dart';

final sl = GetIt.instance;
final pb = PocketBase('https://delivery-app.winganmarketing.com');

Future<void> init() async {
  final objectBoxStore = await ObjectBoxStore.create();
  sl.registerLazySingleton<ObjectBoxStore>(() => objectBoxStore);

  // Add SyncService registration
  sl.registerLazySingleton(() => SyncService());

  // Add this if missing
  await initSyncCubit();
  await initAuth();
  await initUserPerformance();
  await initOnboarding();
  await initChecklist();
  await initGetVehicle();
  await initPersonel(); // Add this
  await initDeliveryTeam(); // Add this
  await initTrip();

  await initDeliveryUpdate();
  await initUpdateTimeline();
  await initOtp();
  await initEndTripOtp();

  await initEndTripChecklist();
  await initTripUpdate();

  //new entities
  await initInvoiceData();
  await initInvoiceStatus();
  await initCustomerData();
  await initInvoiceItems();
  await initDeliveryData();
  await initDeliveryVehicleData();
  await initDeliveryReceipt();
  await initCancelledInvoice();
  await initCollection();
  await initAppLogs();

  sl.registerLazySingleton(() => ConnectivityProvider());
}

Future<void> initSyncCubit() async {
  sl.registerFactory(() => SyncCubit());
}

Future<void> initOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerFactory(
    () => OnboardingBloc(cacheFirstTimer: sl(), checkIfUserIsFirstimer: sl()),
  );

  sl.registerLazySingleton(() => CacheFirstTimer(sl()));

  sl.registerLazySingleton(() => CheckIfUserIsFirstimer(sl()));

  sl.registerLazySingleton<OnboardingRepo>(() => OnboardingRepoImpl(sl()));

  sl.registerLazySingleton<OnboardingLocalDatasource>(
    () => OnboardingLocalDatasourceImpl(sl()),
  );

  sl.registerLazySingleton(() => prefs);
}

Future<void> initAuth() async {
  final prefs = await SharedPreferences.getInstance();
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => AuthBloc(
      signIn: sl(),
      refreshUserData: sl(),
      getUserById: sl(),
      loadUser: sl(),
      getUserTrip: sl(),
      syncUserData: sl(),
      syncUserTripData: sl(),
      connectivity: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => SyncUserData(sl()));
  sl.registerLazySingleton(() => SyncUserTripData(sl()));

  sl.registerLazySingleton(() => GetUserTrip(sl()));
  sl.registerLazySingleton(() => GetUserById(sl()));
  sl.registerLazySingleton(() => LoadUser(sl()));
  sl.registerLazySingleton(() => RefreshUserData(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepo>(() => AuthRepoImpl(sl(), sl()));

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSrc>(
    () => AuthRemoteDataSrcImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSrc>(
    () => AuthLocalDataSrcImpl(objectBoxStore.store, prefs),
  );

  // External
  sl.registerLazySingleton(() => pb);
  sl.registerLazySingleton(() => UserProvider());
}

Future<void> initUserPerformance() async {
  final objectBoxStore = await ObjectBoxStore.create();

  // BLoC
  sl.registerFactory(
    () => UserPerformanceBloc(
      loadUserPerformanceByUserId: sl(),
      calculateDeliveryAccuracy: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoadUserPerformanceByUserId(sl()));
  sl.registerLazySingleton(() => CalculateDeliveryAccuracy(sl()));

  // Repository
  sl.registerLazySingleton<UserPerformanceRepo>(
    () => UserPerformanceRepoImpl(sl(), sl()),
  );

  // Data sources
  sl.registerLazySingleton<UserPerformanceRemoteDatasource>(
    () => UserPerformanceRemoteDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<UserPerformanceLocalDataSource>(
    () => UserPerformanceLocalDataSourceImpl(
      objectBoxStore.store.box<UserPerformanceModel>(),
      objectBoxStore.store,
    ),
  );
}

Future<void> initChecklist() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => ChecklistBloc(
      loadChecklist: sl(),
      checkItem: sl(),
      loadChecklistByTripId: sl(),
    ),
  );

  sl.registerLazySingleton(() => LoadChecklist(sl()));

  sl.registerLazySingleton(() => LoadChecklistByTripId(sl()));

  sl.registerLazySingleton(() => CheckItem(sl()));

  sl.registerLazySingleton<ChecklistRepo>(() => ChecklistRepoImpl(sl(), sl()));

  sl.registerLazySingleton<ChecklistDatasource>(
    () => ChecklistDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<ChecklistLocalDatasource>(
    () => ChecklistLocalDatasourceImpl(
      objectBoxStore.store.box<ChecklistModel>(),
    ),
  );
}

Future<void> initGetVehicle() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => VehicleBloc(
      getVehicle: sl(),
      loadVehicleByTripId: sl(),
      loadVehicleByDeliveryTeam: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetVehicle(sl()));

  sl.registerLazySingleton(() => LoadVehicleByDeliveryTeam(sl()));

  sl.registerLazySingleton(() => LoadVehicleByTripId(sl()));

  sl.registerLazySingleton<VehicleRepo>(() => VehicleRepoImpl(sl(), sl()));

  sl.registerLazySingleton<VehicleRemoteDatasource>(
    () => VehicleRemoteDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<VehicleLocalDatasource>(
    () => VehicleLocalDatasourceImpl(objectBoxStore.store.box<VehicleModel>()),
  );
}

Future<void> initPersonel() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => PersonelBloc(
      getPersonels: sl(),
      setRole: sl(),
      loadPersonelsByTripId: sl(),
      loadPersonelsByDeliveryTeam: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetPersonels(sl()));

  sl.registerLazySingleton(() => SetRole(sl()));

  sl.registerLazySingleton(() => LoadPersonelsByDeliveryTeam(sl()));

  sl.registerLazySingleton(() => LoadPersonelsByTripId(sl()));

  sl.registerLazySingleton<PersonelRepo>(() => PersonelsRepoImpl(sl(), sl()));

  sl.registerLazySingleton<PersonelRemoteDataSource>(
    () => PersonelRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<PersonelLocalDatasource>(
    () =>
        PersonelLocalDatasourceImpl(objectBoxStore.store.box<PersonelModel>()),
  );
}

Future<void> initDeliveryTeam() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => DeliveryTeamBloc(
      loadDeliveryTeam: sl(),
      tripBloc: sl(),
      personelBloc: sl(),
      vehicleBloc: sl(),
      loadDeliveryTeamById: sl(),
      checklistBloc: sl(),
      deliveryVehicleBloc: sl(),
      assignDeliveryTeamToTrip: sl(),
      connectivity: sl(),
    ),
  );

  sl.registerLazySingleton(() => LoadDeliveryTeam(sl()));

  sl.registerLazySingleton(() => LoadDeliveryTeamById(sl()));

  sl.registerLazySingleton(() => AssignDeliveryTeamToTrip(sl()));

  sl.registerLazySingleton<DeliveryTeamRepo>(
    () => DeliveryTeamRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<DeliveryTeamDatasource>(
    () => DeliveryTeamDatasourceImpl(
      pocketBaseClient: sl(),
      deliveryTeamBox: sl(),
    ),
  );

  // Register the Box<DeliveryTeamModel>
  sl.registerLazySingleton<Box<DeliveryTeamModel>>(
    () => objectBoxStore.store.box<DeliveryTeamModel>(),
  );

  sl.registerLazySingleton<DeliveryTeamLocalDatasource>(
    () => DeliveryTeamLocalDatasourceImpl(
      objectBoxStore.store.box<DeliveryTeamModel>(),
    ),
  );
}

Future<void> initTrip() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => TripBloc(
      getTrip: sl(),
      searchTrip: sl(),
      updateTimelineBloc: sl(),
      acceptTrip: sl(),
      checkEndTripStatus: sl(),
      searchTrips: sl(),
      getTripsByDateRange: sl(),
      calculateTotalTripDistance: sl(),
      scanQRUsecase: sl(),
      getTripById: sl(),
      endTrip: sl(),
      updateTripLocation: sl(),
      deliveryDataBloc: sl(),
      checkTripPersonnels: sl(),
      setMismatchedReason: sl(),
      connectivity: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetTrip(sl()));

  sl.registerLazySingleton(() => GetTripById(sl()));

  sl.registerLazySingleton(() => SearchTrip(sl()));

  sl.registerLazySingleton(() => UpdateTripLocation(sl()));

  sl.registerLazySingleton(() => AcceptTrip(sl()));

  sl.registerLazySingleton(() => CheckEndTripStatus(sl()));

  sl.registerLazySingleton(() => SetMismatchedReason(sl()));

  sl.registerLazySingleton(() => SearchTrips(sl()));

  sl.registerLazySingleton(() => GetTripsByDateRange(sl()));

  sl.registerLazySingleton(() => CalculateTotalTripDistance(sl()));

  sl.registerLazySingleton(() => ScanQRUsecase(sl()));

  sl.registerLazySingleton(() => EndTrip(sl()));

  sl.registerLazySingleton(() => CheckTripPersonnels(sl()));

  sl.registerLazySingleton<TripRepo>(() => TripRepoImpl(sl(), sl()));

  sl.registerLazySingleton<TripRemoteDatasurce>(
    () => TripRemoteDatasurceImpl(
      pocketBaseClient: sl(),
      tripLocalDatasource: sl(),
    ),
  );

  sl.registerLazySingleton<TripLocalDatasource>(
    () => TripLocalDatasourceImpl(
      objectBoxStore.store,
      objectBoxStore.store.box<TripModel>(),
      sl(), // Provides the PocketBase client
    ),
  );
}

Future<void> initDeliveryUpdate() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => DeliveryUpdateBloc(
      getDeliveryStatusChoices: sl(),
      updateDeliveryStatus: sl(),
      completeDelivery: sl(),
      checkEndDeliverStatus: sl(),
      initializePendingStatus: sl(),
      createDeliveryStatus: sl(),
      updateQueueRemarks: sl(), pinArrivedLocation: sl(), bulkUpdateDeliveryStatus: sl(), getBulkDeliveryStatusChoices: sl(),
      
    ),
  );
  sl.registerLazySingleton(() => CompleteDelivery(sl()));
  sl.registerLazySingleton(() => GetDeliveryStatusChoices(sl()));
  sl.registerLazySingleton(() => UpdateDeliveryStatus(sl()));
  sl.registerLazySingleton(() => CheckEndDeliverStatus(sl()));
  sl.registerLazySingleton(() => InitializePendingStatus(sl()));
  sl.registerLazySingleton(() => CreateDeliveryStatus(sl()));
  sl.registerLazySingleton(() => GetBulkDeliveryStatusChoices(sl()));
  sl.registerLazySingleton(() => BulkUpdateDeliveryStatus(sl()));
  sl.registerLazySingleton(() => UpdateQueueRemarks(sl()));
  sl.registerLazySingleton( () => PinArrivedLocation(sl()));
  sl.registerLazySingleton<DeliveryUpdateRepo>(
    () => DeliveryUpdateRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<DeliveryUpdateDatasource>(
    () => DeliveryUpdateDatasourceImpl(pocketBaseClient: sl()),
  );
  sl.registerLazySingleton<DeliveryUpdateLocalDatasource>(
    () => DeliveryUpdateLocalDatasourceImpl(
      objectBoxStore.store.box<DeliveryUpdateModel>(),
      objectBoxStore.store.box<DeliveryDataModel>(),
    ),
  );
}

Future<void> initUpdateTimeline() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => UpdateTimelineBloc(loadUpdateTimeline: sl(), setDeliveryUpdate: sl()),
  );

  sl.registerLazySingleton(() => LoadUpdateTimeline(sl()));
  sl.registerLazySingleton(() => SetUpdateTimeline(sl()));

  sl.registerLazySingleton<UpdateTimelineRepo>(
    () => UpdateTimelineRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<UpdateTimelineDatasource>(
    () => UpdateTimelineDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<UpdateTimelineLocalDatasource>(
    () => UpdateTimelineLocalDatasourceImpl(
      objectBoxStore.store.box<UpdateTimelineModel>(),
    ),
  );
}

Future<void> initOtp() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => OtpBloc(
      getGeneratedOtp: sl(),
      verifyEndDelivery: sl(),
      verifyInTransit: sl(),
      loadOtpByTripId: sl(),
      loadOtpById: sl(),
    ),
  );
  sl.registerLazySingleton(() => LoadOtpById(sl()));
  sl.registerLazySingleton(() => LoadOtpByTripId(sl()));
  sl.registerLazySingleton(() => GetGeneratedOtp(sl()));
  sl.registerLazySingleton(() => VerifyInTransit(sl()));
  sl.registerLazySingleton(() => VerifyInEndDelivery(sl()));
  sl.registerLazySingleton<OtpRepo>(() => OtpRepoImpl(sl(), sl()));

  sl.registerLazySingleton<OtpRemoteDataSource>(
    () => OtpRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<OtpLocalDatasource>(
    () => OtpLocalDatasourceImpl(objectBoxStore.store.box<OtpModel>()),
  );
}

Future<void> initEndTripOtp() async {
  final objectBoxStore = await ObjectBoxStore.create();

  // Bloc
  sl.registerFactory(
    () => EndTripOtpBloc(
      verifyEndTripOtp: sl(),
      getGeneratedEndTripOtp: sl(),
      loadEndTripOtpById: sl(),
      loadEndTripOtpByTripId: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => EndOTPVerify(sl()));
  sl.registerLazySingleton(() => GetEndTripGeneratedOtp(sl()));
  sl.registerLazySingleton(() => LoadEndTripOtpByTripId(sl()));
  sl.registerLazySingleton(() => LoadEndTripOtpById(sl()));

  // Repository
  sl.registerLazySingleton<EndTripOtpRepo>(
    () => EndTripOtpRepoImpl(sl(), sl()),
  );

  // Data sources
  sl.registerLazySingleton<EndTripOtpRemoteDataSource>(
    () => EndTripOtpRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<EndTripOtpLocalDatasource>(
    () => EndTripOtpLocalDatasourceImpl(
      objectBoxStore.store.box<EndTripOtpModel>(),
    ),
  );
}

Future<void> initEndTripChecklist() async {
  final objectBoxStore = await ObjectBoxStore.create();

  // Bloc
  sl.registerFactory(
    () => EndTripChecklistBloc(
      generateEndTripChecklist: sl(),
      checkEndTripChecklist: sl(),
      loadEndTripChecklist: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GenerateEndTripChecklist(sl()));
  sl.registerLazySingleton(() => CheckEndTripChecklist(sl()));
  sl.registerLazySingleton(() => LoadEndTripChecklist(sl()));

  // Repository
  sl.registerLazySingleton<EndTripChecklistRepo>(
    () => EndTripChecklistRepoImpl(sl(), sl()),
  );

  // Data sources
  sl.registerLazySingleton<EndTripChecklistRemoteDataSource>(
    () => EndTripChecklistRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<EndTripChecklistLocalDataSource>(
    () => EndTripChecklistLocalDataSourceImpl(
      objectBoxStore.store.box<EndTripChecklistModel>(),
    ),
  );
}

Future<void> initTripUpdate() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerFactory(
    () => TripUpdatesBloc(getTripUpdates: sl(), createTripUpdate: sl()),
  );

  sl.registerLazySingleton(() => GetTripUpdates(sl()));
  sl.registerLazySingleton(() => CreateTripUpdate(sl()));

  sl.registerLazySingleton<TripUpdateRepo>(
    () => TripUpdateRepoImpl(sl(), sl()),
  );

  sl.registerLazySingleton<TripUpdateRemoteDatasource>(
    () => TripUpdateRemoteDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<TripUpdateLocalDatasource>(
    () => TripUpdateLocalDatasourceImpl(
      objectBoxStore.store.box<TripUpdateModel>(),
    ),
  );
}

// Add this function to initialize the DeliveryData feature
Future<void> initDeliveryData() async {
  final objectBoxStore = await ObjectBoxStore.create();

  // BLoC
  sl.registerLazySingleton(
    () => DeliveryDataBloc(
      getAllDeliveryData: sl(),
      getDeliveryDataByTripId: sl(),
      getDeliveryDataById: sl(),
      deleteDeliveryData: sl(),
      setInvoiceIntoUnloading: sl(),
      calculateDeliveryTime: sl(),
      updateDeliveryLocation: sl(),
      syncDeliveryDataByTripId: sl(),
      setInvoiceIntoUnloaded: sl(),
      setInvoiceIntoCompleted: sl(),
      connectivity: sl()
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GetAllDeliveryData(sl()));
  sl.registerLazySingleton(() => GetDeliveryDataByTripId(sl()));
  sl.registerLazySingleton(() => GetDeliveryDataById(sl()));
  sl.registerLazySingleton(() => DeleteDeliveryData(sl()));
  sl.registerLazySingleton(() => SetInvoiceIntoCompleted(sl()));
  sl.registerLazySingleton(() => CalculateDeliveryTimeByDeliveryId(sl()));
  sl.registerLazySingleton(() => SyncDeliveryDataByTripId(sl()));
  sl.registerLazySingleton(() => SetInvoiceIntoUnloading(sl()));
  sl.registerLazySingleton(() => UpdateDeliveryLocation(sl()));
  sl.registerLazySingleton(() => SetInvoiceIntoUnloaded(sl()));

  // Repository
  sl.registerLazySingleton<DeliveryDataRepo>(
    () => DeliveryDataRepoImpl(sl(), sl()),
  );

  // Data sources
  sl.registerLazySingleton<DeliveryDataRemoteDataSource>(
    () => DeliveryDataRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<DeliveryDataLocalDataSource>(
    () => DeliveryDataLocalDataSourceImpl(
      objectBoxStore.store.box<DeliveryDataModel>(),
      sl<Store>(),
    ),
  );
}

Future<void> initDeliveryVehicleData() async {
  sl.registerLazySingleton(
    () => DeliveryVehicleBloc(
      loadDeliveryVehicleById: sl(),
      loadDeliveryVehiclesByTripId: sl(),
      loadAllDeliveryVehicles: sl(),
    ),
  );

  sl.registerLazySingleton(() => LoadDeliveryVehicleById(sl()));
  sl.registerLazySingleton(() => LoadDeliveryVehiclesByTripId(sl()));
  sl.registerLazySingleton(() => LoadAllDeliveryVehicles(sl()));

  sl.registerLazySingleton<DeliveryVehicleRepo>(
    () => DeliveryVehicleRepoImpl(sl()),
  );

  sl.registerLazySingleton<DeliveryVehicleRemoteDataSource>(
    () => DeliveryVehicleRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initInvoiceData() async {
  sl.registerLazySingleton(
    () => InvoiceDataBloc(
      getAllInvoiceData: sl(),
      getInvoiceDataById: sl(),
      getInvoiceDataByDeliveryId: sl(),
      getInvoiceDataByCustomerId: sl(),
      addInvoiceDataToDelivery: sl(),
      addInvoiceDataToInvoiceStatus: sl(),
      setInvoiceUnloaded: sl()
    ),
  );

  sl.registerLazySingleton(() => GetAllInvoiceData(sl()));
  sl.registerLazySingleton(() => GetInvoiceDataByCustomerId(sl()));
  sl.registerLazySingleton(() => GetInvoiceDataById(sl()));
  sl.registerLazySingleton(() => GetInvoiceDataByDeliveryId(sl()));
  sl.registerLazySingleton(() => AddInvoiceDataToDelivery(sl()));
  sl.registerLazySingleton(() => AddInvoiceDataToInvoiceStatus(sl()));
  sl.registerLazySingleton(() => SetInvoiceUnloaded(sl()));

  sl.registerLazySingleton<InvoiceDataRepo>(() => InvoiceDataRepoImpl(sl()));
  sl.registerLazySingleton<InvoiceDataRemoteDataSource>(
    () => InvoiceDataRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initInvoiceStatus() async {
  final objectBoxStore = await ObjectBoxStore.create();

  // BLoC
  sl.registerLazySingleton(
    () => InvoiceStatusBloc(
      getInvoiceStatusByInvoiceId: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GetInvoiceStatusByInvoiceId(sl()));

  // Repository
  sl.registerLazySingleton<InvoiceStatusRepo>(() => InvoiceStatusRepoImpl(
    remoteDataSource: sl(),
    localDataSource: sl(),
  ));

  // Remote DataSource
  sl.registerLazySingleton<InvoiceStatusRemoteDataSource>(
    () => InvoiceStatusRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  // Local DataSource
  sl.registerLazySingleton<InvoiceStatusLocalDataSource>(
    () => InvoiceStatusLocalDataSourceImpl(store: objectBoxStore.store),
  );
}

// Add this function to the init section
Future<void> initInvoiceItems() async {
  final objectBoxStore = await ObjectBoxStore.create();

  // BLoC
  sl.registerLazySingleton(
    () => InvoiceItemsBloc(
      getInvoiceItemsByInvoiceDataId: sl(),
      getAllInvoiceItems: sl(),
      updateInvoiceItemById: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => GetInvoiceItemsByInvoiceDataId(sl()));
  sl.registerLazySingleton(() => GetAllInvoiceItems(sl()));
  sl.registerLazySingleton(() => UpdateInvoiceItemById(sl()));

  // Repository
  sl.registerLazySingleton<InvoiceItemsRepo>(
    () => InvoiceItemsRepoImpl(sl(), sl()),
  );

  // Data sources
  sl.registerLazySingleton<InvoiceItemsRemoteDataSource>(
    () => InvoiceItemsRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<InvoiceItemsLocalDataSource>(
    () => InvoiceItemsLocalDataSourceImpl(
      objectBoxStore.store.box<InvoiceItemsModel>(),
    ),
  );
}

Future<void> initCustomerData() async {
  sl.registerLazySingleton(
    () => CustomerDataBloc(
      getAllCustomerData: sl(),
      getCustomerDataById: sl(),
      createCustomerData: sl(),
      updateCustomerData: sl(),
      deleteCustomerData: sl(),
      deleteAllCustomerData: sl(),
      addCustomerToDelivery: sl(),
      getCustomersByDeliveryId: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetAllCustomerData(sl()));
  sl.registerLazySingleton(() => GetCustomerDataById(sl()));
  sl.registerLazySingleton(() => CreateCustomerData(sl()));
  sl.registerLazySingleton(() => UpdateCustomerData(sl()));
  sl.registerLazySingleton(() => DeleteCustomerData(sl()));
  sl.registerLazySingleton(() => DeleteAllCustomerData(sl()));
  sl.registerLazySingleton(() => AddCustomerToDelivery(sl()));
  sl.registerLazySingleton(() => GetCustomersByDeliveryId(sl()));

  sl.registerLazySingleton<CustomerDataRepo>(() => CustomerDataRepoImpl(sl()));
  sl.registerLazySingleton<CustomerDataRemoteDataSource>(
    () => CustomerDataRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initDeliveryReceipt() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerLazySingleton(
    () => DeliveryReceiptBloc(
      createDeliveryReceipt: sl(),
      deleteDeliveryReceipt: sl(),
      getDeliveryReceiptByTripId: sl(),
      getDeliveryReceiptByDeliveryDataId: sl(),
      generateDeliveryReceiptPdf: sl(),
    ),
  );

  sl.registerLazySingleton(() => CreateDeliveryReceipt(sl()));
  sl.registerLazySingleton(() => DeleteDeliveryReceipt(sl()));
  sl.registerLazySingleton(() => GetDeliveryReceiptByTripId(sl()));
  sl.registerLazySingleton(() => GetDeliveryReceiptByDeliveryDataId(sl()));
  sl.registerLazySingleton(() => GenerateDeliveryReceiptPdf(sl()));

  sl.registerLazySingleton<DeliveryReceiptRepo>(
    () =>
        DeliveryReceiptRepoImpl(remoteDatasource: sl(), localDatasource: sl()),
  );

  sl.registerLazySingleton<DeliveryReceiptRemoteDatasource>(
    () => DeliveryReceiptRemoteDatasourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<DeliveryReceiptLocalDatasource>(
    () => DeliveryReceiptLocalDatasourceImpl(
      objectBoxStore.store.box<DeliveryReceiptModel>(),
    ),
  );
}

Future<void> initCancelledInvoice() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerLazySingleton(
    () => CancelledInvoiceBloc(
      deleteCancelledInvoice: sl(),
      loadCancelledInvoicesByTripId: sl(),
      loadCancelledInvoicesById: sl(),
      createCancelledInvoiceByDeliveryDataId: sl(),
      connectivity: sl(),
    ),
  );

  sl.registerLazySingleton(() => LoadCancelledInvoiceById(sl()));
  sl.registerLazySingleton(() => LoadCancelledInvoicesByTripId(sl()));

  sl.registerLazySingleton(() => CreateCancelledInvoiceByDeliveryDataId(sl()));
  sl.registerLazySingleton(() => DeleteCancelledInvoice(sl()));

  sl.registerLazySingleton<CancelledInvoiceRepo>(
    () =>
        CancelledInvoiceRepoImpl(localDataSource: sl(), remoteDataSource: sl()),
  );

  sl.registerLazySingleton<CancelledInvoiceLocalDataSource>(
    () => CancelledInvoiceLocalDataSourceImpl(
      cancelledInvoiceBox: objectBoxStore.store.box<CancelledInvoiceModel>(),
      deliveryDataBox: objectBoxStore.store.box<DeliveryDataModel>(),
      tripBox: objectBoxStore.store.box<TripModel>(),
    ),
  );

  sl.registerLazySingleton<CancelledInvoiceRemoteDataSource>(
    () => CancelledInvoiceRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initCollection() async {
  final objectBoxStore = await ObjectBoxStore.create();

  sl.registerLazySingleton(
    () => CollectionsBloc(
      getCollectionsByTripId: sl(),
      getCollectionById: sl(),
      deleteCollection: sl(),
      connectivity: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetCollectionsByTripId(sl()));
  sl.registerLazySingleton(() => GetCollectionById(sl()));
  sl.registerLazySingleton(() => DeleteCollection(sl()));

  sl.registerLazySingleton<CollectionRepo>(
    () => CollectionRepoImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  sl.registerLazySingleton<CollectionLocalDataSource>(
    () => CollectionLocalDataSourceImpl(objectBoxStore.store.box()),
  );
  sl.registerLazySingleton<CollectionRemoteDataSource>(
    () => CollectionRemoteDataSourceImpl(pocketBaseClient: sl()),
  );
}

Future<void> initReturnItems() async {
  final objectBoxStore = await ObjectBoxStore.create();

  // BLoC
  sl.registerFactory(
    () => ReturnItemsBloc(
      getReturnItemsByTripId: sl(),
      getReturnItemById: sl(),
      addItemsToReturnItemsByDeliveryId: sl(),
      returnItemsRepo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetReturnItemsByTripId(sl()));
  sl.registerLazySingleton(() => GetReturnItemById(sl()));
  sl.registerLazySingleton(() => AddItemsToReturnItemsByDeliveryId(sl()));

  // Repository
  sl.registerLazySingleton<ReturnItemsRepo>(
    () => ReturnItemsRepoImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ReturnItemsRemoteDataSource>(
    () => ReturnItemsRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  sl.registerLazySingleton<ReturnItemsLocalDataSource>(
    () => ReturnItemsLocalDataSourceImpl(
      objectBoxStore.store.box<ReturnItemsModel>(),
      objectBoxStore.store,
    ),
  );
}

Future<void> initAppLogs() async {
  // BLoC
  sl.registerLazySingleton(
    () => LogsBloc(
      getLogs: sl(),
      clearLogs: sl(),
      downloadLogsPdf: sl(),
      addLog: sl(),
      syncLogsToRemote: sl(),
      getUnsyncedLogs: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetLogs(sl()));
  sl.registerLazySingleton(() => ClearLogs(sl()));
  sl.registerLazySingleton(() => DownloadLogsPdf(sl()));
  sl.registerLazySingleton(() => AddLog(sl()));
  sl.registerLazySingleton(() => SyncLogsToRemote(sl()));
  sl.registerLazySingleton(() => GetUnsyncedLogs(sl()));
  sl.registerLazySingleton(() => MarkLogsAsSynced(sl()));

  // Repository
  sl.registerLazySingleton<LogsRepo>(
    () => LogsRepoImpl(
      logsLocalDatasource: sl(),
      logsRemoteDataSource: sl(),
    ),
  );

  // Local DataSource
  sl.registerLazySingleton<LogsLocalDatasource>(
    () => LogsLocalDatasourceImpl(),
  );

  // Remote DataSource
  sl.registerLazySingleton<LogsRemoteDataSource>(
    () => LogsRemoteDataSourceImpl(pocketBaseClient: sl()),
  );

  // Initialize AppLogger with the AddLog usecase
  AppLogger.instance.initialize(sl<AddLog>());
}
