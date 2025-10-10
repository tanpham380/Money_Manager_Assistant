import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';
import '../services/alert_service.dart';

class MainLockScreen extends StatefulWidget {
  const MainLockScreen({Key? key}) : super(key: key);

  @override
  State<MainLockScreen> createState() => _MainLockScreenState();
}

class _MainLockScreenState extends State<MainLockScreen>
    with TickerProviderStateMixin {
  late AnimationController _fingerprintAnimController;
  late Animation<double> _fingerprintScale;

  @override
  void initState() {
    super.initState();
    _fingerprintAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fingerprintScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _fingerprintAnimController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _fingerprintAnimController.dispose();
    super.dispose();
  }

  // === AUTHENTICATION LOGIC ===
  Future<void> localAuth(BuildContext context) async {
    final localAuth = LocalAuthentication();
    final canAuthenticate = await localAuth.canCheckBiometrics ||
        await localAuth.isDeviceSupported();

    if (!canAuthenticate) {
      AlertService.show(
        context,
        type: NotificationType.error,
        message: 'Your device does not have a screen lock',
      );
      return;
    }

    final didAuthenticate = await localAuth.authenticate(
      localizedReason: getTranslated(
            context,
            'Scan your fingerprint to authenticate',
          ) ??
          'Please authenticate to continue',
      options: const AuthenticationOptions(
        stickyAuth: true,
      ),
    );

    if (didAuthenticate && context.mounted) {
      await showDialog(
        context: context,
        builder: (_) => Center(
          child: Lottie.asset(
            'assets/images/unlock_success.json',
            repeat: false,
            width: 150,
          ),
        ),
      );

      AppLock.of(context)!.didUnlock();
    }
  }

  Future<void> _onFingerprintTap() async {
    await _fingerprintAnimController.forward();
    await _fingerprintAnimController.reverse();
    await localAuth(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD2EAFB),
              Color(0xFFB8E0F7),
              Color(0xFFD2EAFB),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Animation BANK ở đầu
              Lottie.asset(
                'assets/images/BANK.json',
                width: 200,
                height: 200,
                repeat: true,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),

              // Tiêu đề
              Text(
                getTranslated(context, 'Please Enter Passcode') ??
                    'Please Enter Passcode',
                style: const TextStyle(
                  color: Color(0xFF477FC0),
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),

              // ScreenLock chính — bọc Expanded để có giới hạn kích thước
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ScreenLock(
                      correctString: sharedPrefs.passcodeScreenLock,
                      onUnlocked: () => AppLock.of(context)!.didUnlock(),
                      config: const ScreenLockConfig(
                        backgroundColor: Colors.transparent,
                      ),
                      secretsConfig: const SecretsConfig(
                        secretConfig: SecretConfig(
                          borderColor: Color(0xFF4F5E78),
                          enabledColor: Color(0xFF5981A3),
                        ),
                      ),
                      deleteButton: const Icon(
                        Icons.close,
                        color: Color(0xFF5981A3),
                        size: 28,
                      ),
                      customizedButtonChild: AnimatedBuilder(
                        animation: _fingerprintScale,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _fingerprintScale.value,
                            child: Lottie.asset(
                              'assets/images/Fingerprint.json',
                              width: 80,
                              repeat: true,
                            ),
                          );
                        },
                      ),
                      customizedButtonTap: _onFingerprintTap,
                    ),
                  ),
                ),
              ),

              // Gợi ý thêm bên dưới
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Text(
                  getTranslated(context, 'Touch fingerprint to unlock') ??
                      'Touch fingerprint to unlock',
                  style: const TextStyle(
                    color: Color(0xFF527FBA),
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
