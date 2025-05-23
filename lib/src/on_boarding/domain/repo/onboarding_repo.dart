import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class OnboardingRepo {
  const OnboardingRepo();

   ResultFuture<void> cacheFirstTimer();

  ResultFuture<bool> checkIfUserIsFirstTimer();
}