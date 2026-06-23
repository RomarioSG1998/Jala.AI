import 'package:flutter_riverpod/flutter_riverpod.dart';

class PurchasedProductsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return {}; // Começa vazio
  }

  void purchase(String productId) {
    state = {...state, productId};
  }
}

final purchasedProductsProvider = NotifierProvider<PurchasedProductsNotifier, Set<String>>(() {
  return PurchasedProductsNotifier();
});
