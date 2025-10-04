import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:local_auth/local_auth.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';

class MainLockScreen extends StatelessWidget {
  const MainLockScreen({Key? key}) : super(key: key);

  Future<void> localAuth(BuildContext context) async {
    final localAuth = LocalAuthentication();
    final didAuthenticate = await localAuth.canCheckBiometrics;

    if (didAuthenticate) {
      final authenticated = await localAuth.authenticate(
        localizedReason: getTranslated(
              context,
              'Scan your fingerprint to authenticate',
            ) ??
            'Scan your fingerprint to authenticate',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated) {
        AppLock.of(context)!.didUnlock();
      }
    } else {
      await _cancelAuthentication(localAuth);
    }
  }

  Future<void> _cancelAuthentication(LocalAuthentication auth) async {
    await auth.stopAuthentication();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenLock(
      correctString: sharedPrefs.passcodeScreenLock,
      // Remove the 'canCancel' parameter
      // canCancel: false,
      customizedButtonChild: Icon(Icons.fingerprint),
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
          style: TextStyle(
              color: Color.fromRGBO(71, 131, 192, 1),
              fontWeight: FontWeight.w500,
              fontSize: 20),
        ),
      ),
      config: const ScreenLockConfig(
        backgroundColor: Color.fromRGBO(210, 234, 251, 1),
      ),
      secretsConfig: SecretsConfig(
          secretConfig: SecretConfig(
        borderColor: Color.fromRGBO(79, 94, 120, 1),
        enabledColor: Color.fromRGBO(89, 129, 163, 1),
      )),
    );
  }
}
