import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/domain/entity/delivery_team_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/domain/repo/delivery_team_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class LoadDeliveryTeamById extends UsecaseWithParams<DeliveryTeamEntity, String> {
  const LoadDeliveryTeamById(this._repo);

  final DeliveryTeamRepo _repo;

  @override
  ResultFuture<DeliveryTeamEntity> call(String params) => _repo.loadDeliveryTeamById(params);
  
  ResultFuture<DeliveryTeamEntity> loadFromLocal(String params) => _repo.loadLocalDeliveryTeamById(params);
}

