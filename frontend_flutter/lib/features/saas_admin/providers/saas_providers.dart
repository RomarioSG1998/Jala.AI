import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_models.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_repository.dart';

// Plans provider
class PlansNotifier extends AsyncNotifier<List<SaasPlan>> {
  @override
  Future<List<SaasPlan>> build() async {
    return ref.watch(saasAdminRepositoryProvider).getPlans();
  }
}

final plansProvider =
    AsyncNotifierProvider<PlansNotifier, List<SaasPlan>>(() => PlansNotifier());

// Tenants provider
class TenantsNotifier extends AsyncNotifier<List<FarmTenant>> {
  @override
  Future<List<FarmTenant>> build() async {
    return ref.watch(saasAdminRepositoryProvider).getAllTenants();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(
          await ref.read(saasAdminRepositoryProvider).getAllTenants());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createTenant(String name, String cnpj) async {
    try {
      final success = await ref.read(saasAdminRepositoryProvider).createTenant(name, cnpj);
      if (success) {
        await refresh();
      }
      return success;
    } catch (_) {
      return false;
    }
  }
}

final tenantsProvider =
    AsyncNotifierProvider<TenantsNotifier, List<FarmTenant>>(
        () => TenantsNotifier());
