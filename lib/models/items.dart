class Item {
  int? id;
  String name;
  String description;
  double price;
  String category;
  int quantity;

  Item({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'quantity': quantity,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) => Item(
        id: map['id'],
        name: map['name'],
        description: map['description'],
        price: map['price'],
        category: map['category'],
        quantity: map['quantity'],
      );
}
