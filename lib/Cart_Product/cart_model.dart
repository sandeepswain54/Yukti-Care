class CartItem {
  final String productId;
  final String name;
  final String image;
  final double unitPrice;
  final double mrp;
  int quantity;
  final String? size;
  final String? color;

  CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.unitPrice,
    required this.mrp,
    this.quantity = 1,
    this.size,
    this.color,
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'image': image,
      'unitPrice': unitPrice,
      'mrp': mrp,
      'quantity': quantity,
      'size': size,
      'color': color,
    };
  }

  static CartItem fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return CartItem(
      productId: map['productId'],
      name: map['name'],
      image: map['image'],
      unitPrice: parseDouble(map['unitPrice']),
      mrp: parseDouble(map['mrp']),
      quantity: map['quantity'],
      size: map['size'],
      color: map['color'],
    );
  }
}