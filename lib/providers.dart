import 'package:enmkit/core/sms_service.dart';
import 'package:enmkit/repositories/kit_repository.dart';
import 'package:enmkit/viewmodels/authViewModel.dart';
import 'package:enmkit/viewmodels/kitViewModel.dart';
import 'package:enmkit/viewmodels/onboarding_vm.dart';
import 'package:enmkit/viewmodels/relayViewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/repositories/auth_repository.dart';


final onboardingVMProvider = ChangeNotifierProvider((ref) => OnboardingVM());
/// Provider pour DBService singleton
final dbServiceProvider = Provider<DBService>((ref) => DBService());

/// Provider pour AuthRepository
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(dbServiceProvider)),
);

final authProvider = StateNotifierProvider<AuthVM, AuthState>(
  (ref) => AuthVM(ref.read(authRepositoryProvider)),
);


// Instance du ViewModel des relais
final relaysProvider = ChangeNotifierProvider<RelayViewModel>((ref) {
  final dbService = DBService(); // Assurez-vous qu'il est singleton ou initialisé
  final kitRepo = KitRepository(dbService);
  final smsService = SmsService(kitRepo);
  return RelayViewModel(dbService, smsService);
});

// Provider pour KitViewModel
final kitProvider = ChangeNotifierProvider<KitViewModel>((ref) {
  final dbService = DBService(); // Assurez-vous que c'est singleton ou correctement initialisé
  return KitViewModel(dbService);
});