import 'package:flutter/foundation.dart';
import 'cart_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  void addToCart(CartItem newItem) {
    final existingIndex = _items.indexWhere(
      (item) => item.productId == newItem.productId && item.size == newItem.size && item.color == newItem.color
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += newItem.quantity;
    } else {
      _items.add(newItem);
    }
    notifyListeners();
  }

  void removeFromCart(String productId, {String? size, String? color}) {
    _items.removeWhere(
      (item) => item.productId == productId && item.size == size && item.color == color
    );
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity, {String? size, String? color}) {
    final index = _items.indexWhere(
      (item) => item.productId == productId && item.size == size && item.color == color
    );
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}