import 'package:enmkit/viewmodels/onboarding_vm.dart';
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
