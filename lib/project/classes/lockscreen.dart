import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // *** THÊM IMPORT NÀY ***
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:local_auth/local_auth.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';

class MainLockScreen extends StatelessWidget {
  const MainLockScreen({Key? key}) : super(key: key);

  // *** PHẦN 2: LOGIC LOCALAUTH ĐÃ ĐƯỢC TỐI ƯU ***
  Future<void> localAuth(BuildContext context) async {
    final localAuth = LocalAuthentication();

    // Kiểm tra xem thiết bị có hỗ trợ bất kỳ hình thức xác thực nào không
    // (Vân tay, Face ID, PIN, Mẫu hình...)
    final canAuthenticate =
        await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();

    if (!canAuthenticate) {
      // Nếu không có, thông báo cho người dùng (tùy chọn) và không làm gì cả
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Thiết bị của bạn không có khóa màn hình.')),
        );
      }
      return;
    }

    try {
      final didAuthenticate = await localAuth.authenticate(
        localizedReason: getTranslated(
              context,
              'Scan your fingerprint to authenticate',
            ) ??
            'Please authenticate to continue',
        options: const AuthenticationOptions(
          stickyAuth: true, // Rất quan trọng, giữ xác thực khi app bị che khuất
          // Bỏ 'biometricOnly: true' để cho phép dùng cả PIN/Mẫu hình của thiết bị
          // nếu vân tay thất bại nhiều lần. Đây là trải nghiệm người dùng tốt hơn.
        ),
      );

      // Kiểm tra widget còn tồn tại không trước khi gọi didUnlock
      if (didAuthenticate && context.mounted) {
        AppLock.of(context)!.didUnlock();
      }
    } on PlatformException catch (e) {
      // Xử lý lỗi, ví dụ: người dùng hủy bỏ
      print("Lỗi xác thực: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenLock(
      correctString: sharedPrefs.passcodeScreenLock,
      customizedButtonChild: const Icon(Icons.fingerprint),
      customizedButtonTap: () async => await localAuth(context),
      onUnlocked: () => AppLock.of(context)!.didUnlock(),
      deleteButton:
          const Icon(Icons.close, color: Color.fromRGBO(89, 129, 163, 1)),
      title: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          getTranslated(
                context,
                'Please Enter Passcode',
              ) ??
              'Please Enter Passcode',
          style: const TextStyle(
              color: Color.fromRGBO(71, 131, 192, 1),
              fontWeight: FontWeight.w500,
              fontSize: 20),
        ),
      ),
      config: const ScreenLockConfig(
        backgroundColor: Color.fromRGBO(210, 234, 251, 1),
      ),
      secretsConfig: const SecretsConfig(
        secretConfig: SecretConfig(
          borderColor: Color.fromRGBO(79, 94, 120, 1),
          enabledColor: Color.fromRGBO(89, 129, 163, 1),
        ),
      ),
    );
  }
}