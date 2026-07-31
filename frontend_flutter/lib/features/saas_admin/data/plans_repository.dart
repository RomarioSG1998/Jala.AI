import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/saas_admin/providers/saas_providers.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class SaasPlanDetail {
  final String id;
  final String name;
  final int maxTanks;
  final int maxUsers;
  final double priceMonthly;
  final String? stripeProductId;
  final String? stripePriceId;
  final String? description;
  final bool active;
  final int activeSubscribers;
  final int totalSubscribers;

  SaasPlanDetail({
    required this.id,
    required this.name,
    required this.maxTanks,
    required this.maxUsers,
    required this.priceMonthly,
    this.stripeProductId,
    this.stripePriceId,
    this.description,
    this.active = true,
    required this.activeSubscribers,
    required this.totalSubscribers,
  });

  factory SaasPlanDetail.fromJson(Map<String, dynamic> json) => SaasPlanDetail(
        id: json['id'] as String,
        name: json['name'] as String,
        maxTanks: json['maxTanks'] as int? ?? 0,
        maxUsers: json['maxUsers'] as int? ?? 0,
        priceMonthly: (json['priceMonthly'] as num?)?.toDouble() ?? 0.0,
        stripeProductId: json['stripeProductId']?.toString(),
        stripePriceId: json['stripePriceId']?.toString(),
        description: json['description']?.toString(),
        active: json['active'] != false,
        activeSubscribers: json['activeSubscribers'] as int? ?? 0,
        totalSubscribers: json['totalSubscribers'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'maxTanks': maxTanks,
        'maxUsers': maxUsers,
        'priceMonthly': priceMonthly,
        'description': description,
      };
}

// ─── Repository ──────────────────────────────────────────────────────────────

class PlansRepository {
  final Dio _dio;
  PlansRepository(this._dio);

  Future<List<SaasPlanDetail>> getPlansWithDetails() async {
    final response = await _dio.get('/api/billing/plans/details');
    final List<dynamic> data = response.data;
    return data.map((j) => SaasPlanDetail.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<SaasPlanDetail> createPlan({
    required String name,
    required int maxTanks,
    required int maxUsers,
    required double priceMonthly,
    String? description,
  }) async {
    final response = await _dio.post('/api/saas-plans', data: {
      'name': name,
      'maxTanks': maxTanks,
      'maxUsers': maxUsers,
      'priceMonthly': priceMonthly,
      'description': description,
    });
    final json = response.data as Map<String, dynamic>;
    json['activeSubscribers'] = 0;
    json['totalSubscribers'] = 0;
    return SaasPlanDetail.fromJson(json);
  }

  Future<SaasPlanDetail> updatePlan({
    required String id,
    required String name,
    required int maxTanks,
    required int maxUsers,
    required double priceMonthly,
    String? description,
  }) async {
    final response = await _dio.put('/api/saas-plans/$id', data: {
      'name': name,
      'maxTanks': maxTanks,
      'maxUsers': maxUsers,
      'priceMonthly': priceMonthly,
      'description': description,
    });
    final json = response.data as Map<String, dynamic>;
    json['activeSubscribers'] = 0;
    json['totalSubscribers'] = 0;
    return SaasPlanDetail.fromJson(json);
  }

  Future<void> deletePlan(String id) async {
    await _dio.delete('/api/saas-plans/$id');
  }
}

final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepository(ref.watch(dioProvider));
});

// ─── Notifier ─────────────────────────────────────────────────────────────────

class PlansDetailNotifier extends AsyncNotifier<List<SaasPlanDetail>> {
  @override
  Future<List<SaasPlanDetail>> build() async {
    return ref.watch(plansRepositoryProvider).getPlansWithDetails();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(
          await ref.read(plansRepositoryProvider).getPlansWithDetails());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<String?> createPlan({
    required String name,
    required int maxTanks,
    required int maxUsers,
    required double priceMonthly,
    String? description,
  }) async {
    try {
      await ref.read(plansRepositoryProvider).createPlan(
            name: name,
            maxTanks: maxTanks,
            maxUsers: maxUsers,
            priceMonthly: priceMonthly,
            description: description,
          );
      await refresh();
      ref.invalidate(plansProvider);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> updatePlan({
    required String id,
    required String name,
    required int maxTanks,
    required int maxUsers,
    required double priceMonthly,
    String? description,
  }) async {
    try {
      await ref.read(plansRepositoryProvider).updatePlan(
            id: id,
            name: name,
            maxTanks: maxTanks,
            maxUsers: maxUsers,
            priceMonthly: priceMonthly,
            description: description,
          );
      await refresh();
      ref.invalidate(plansProvider);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> deletePlan(String id) async {
    try {
      await ref.read(plansRepositoryProvider).deletePlan(id);
      await refresh();
      ref.invalidate(plansProvider);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}

final plansDetailProvider =
    AsyncNotifierProvider<PlansDetailNotifier, List<SaasPlanDetail>>(
        PlansDetailNotifier.new);
