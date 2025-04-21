import 'package:x_pro_delivery_app/core/common/app/features/otp/domain/entity/otp_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class OtpRepo {
  ResultFuture<String> getGeneratedOtp();

  ResultFuture<OtpEntity> loadOtpByTripId(String tripId);

    ResultFuture<OtpEntity> loadOtpById(String otpId);

  
  ResultFuture<bool> verifyInTransitOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
  });

  ResultFuture<bool> verifyEndDeliveryOtp({
    required String enteredOtp,
    required String generatedOtp,
  });
}

