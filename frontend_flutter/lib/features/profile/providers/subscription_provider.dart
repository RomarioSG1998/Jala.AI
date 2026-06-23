import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserSubscriptionPlan { free, pro }

class UserSubscriptionNotifier extends Notifier<UserSubscriptionPlan> {
  @override
  UserSubscriptionPlan build() {
    return UserSubscriptionPlan.free; // Começa no plano gratuito para testar o limite de 1 tanque!
  }

  void selectPlan(UserSubscriptionPlan plan) {
    state = plan;
  }
}

final userSubscriptionProvider = NotifierProvider<UserSubscriptionNotifier, UserSubscriptionPlan>(() {
  return UserSubscriptionNotifier();
});
