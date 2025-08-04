class SoldItem {
  int? id;
  String name;
  double costPrice;
  double sellPrice;
  String date;

  SoldItem({
    this.id,
    required this.name,
    required this.costPrice,
    required this.sellPrice,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'costPrice': costPrice,
      'sellPrice': sellPrice,
      'date': date,
    };
  }

  factory SoldItem.fromMap(Map<String, dynamic> map) => SoldItem(
        id: map['id'],
        name: map['name'],
        costPrice: map['costPrice'],
        sellPrice: map['sellPrice'],
        date: map['date'],
      );
}


