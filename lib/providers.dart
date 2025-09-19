import 'package:enmkit/viewmodels/authViewModel.dart';
import 'package:enmkit/viewmodels/onboarding_vm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/repositories/auth_repository.dart';
import 'package:enmkit/repositories/relay_repository.dart';
import 'package:enmkit/models/relay_model.dart';
import 'package:enmkit/repositories/kit_repository.dart';
import 'package:enmkit/repositories/allowed_number_repository.dart';
import 'package:enmkit/core/sms_service.dart';


final onboardingVMProvider = ChangeNotifierProvider((ref) => OnboardingVM());
/// Provider pour DBService singleton
final dbServiceProvider = Provider<DBService>((ref) => DBService());

/// Provider pour AuthRepository
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(dbServiceProvider)),
);

/// Provider pour RelayRepository
final relayRepositoryProvider = Provider<RelayRepository>(
  (ref) => RelayRepository(ref.read(dbServiceProvider)),
);

/// Relays depuis la base locale (lecture ponctuelle)
final dbRelaysProvider = FutureProvider<List<RelayModel>>((ref) async {
  final repo = ref.read(relayRepositoryProvider);
  return repo.getAllRelays();
});

/// Provider pour KitRepository
final kitRepositoryProvider = Provider<KitRepository>(
  (ref) => KitRepository(ref.read(dbServiceProvider)),
);

/// Provider pour SmsService
final smsServiceProvider = Provider<SmsService>(
  (ref) => SmsService(ref.read(kitRepositoryProvider)),
);

/// Provider pour AllowedNumberRepository
final allowedNumberRepositoryProvider = Provider<AllowedNumberRepository>(
  (ref) => AllowedNumberRepository(ref.read(dbServiceProvider)),
);

final authProvider = StateNotifierProvider<AuthVM, AuthState>(
  (ref) => AuthVM(ref.read(authRepositoryProvider)),
);
