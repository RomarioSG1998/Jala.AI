import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/approvals/data/approval_model.dart';
import 'package:frontend_flutter/features/approvals/data/approval_repository.dart';

class ApprovalNotifier extends AsyncNotifier<List<ApprovalRequestModel>> {
  late final ApprovalRepository _repository;

  @override
  FutureOr<List<ApprovalRequestModel>> build() async {
    _repository = ref.watch(approvalRepositoryProvider);
    return _repository.getApprovalRequests();
  }

  Future<void> refreshRequests() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getApprovalRequests());
  }

  Future<bool> resolveRequest(String requestId, String status) async {
    try {
      final updated = await _repository.resolveApprovalRequest(requestId, status);
      
      // Update local state if the list is already loaded
      if (state.hasValue) {
        final currentList = state.value!;
        state = AsyncValue.data(
          currentList.map((req) => req.id == requestId ? updated : req).toList(),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

final approvalNotifierProvider = AsyncNotifierProvider<ApprovalNotifier, List<ApprovalRequestModel>>(() {
  return ApprovalNotifier();
});
