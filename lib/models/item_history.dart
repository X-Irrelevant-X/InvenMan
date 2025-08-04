// models/item_history.dart
class ItemHistory {
  int? id;
  String name;
  String action;
  String date;
  String detail;

  ItemHistory({
    this.id,
    required this.name,
    required this.action,
    required this.date,
    required this.detail,
  });

  factory ItemHistory.fromMap(Map<String, dynamic> map) {
    return ItemHistory(
      id: map['id'],
      name: map['name'],
      action: map['action'],
      date: map['date'],
      detail: map['detail'],
    );
  }
}
