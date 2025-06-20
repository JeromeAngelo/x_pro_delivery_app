import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/repo/delivery_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class SetInvoiceIntoUnloading extends UsecaseWithParams<DeliveryDataEntity, String> {
  const SetInvoiceIntoUnloading(this._repo);

  final DeliveryDataRepo _repo;

  @override
  ResultFuture<DeliveryDataEntity> call(String deliveryDataId) async {
    return _repo.setInvoiceIntoUnloading(deliveryDataId);
  }
}
