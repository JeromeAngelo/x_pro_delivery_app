

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/repo/delivery_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetDeliveryDataByTripId extends UsecaseWithParams<List<DeliveryDataEntity>, String> {
  const GetDeliveryDataByTripId(this._repo);

  final DeliveryDataRepo _repo;

  @override
  ResultFuture<List<DeliveryDataEntity>> call(String params) => _repo.getDeliveryDataByTripId(params);
    ResultFuture<List<DeliveryDataEntity>> loadFromLocal(String params) => _repo.getLocalDeliveryDataByTripId(params);

}
