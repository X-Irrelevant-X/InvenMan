// db.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ivenman/models/items.dart';
import 'package:ivenman/models/sold_items.dart';
import 'package:ivenman/models/item_history.dart';  // NEW

class DBHelper {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'inventory.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          description TEXT,
          price REAL,
          category TEXT,
          quantity INTEGER)''');
        await db.execute('''CREATE TABLE sold_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          costPrice REAL,
          sellPrice REAL,
          date TEXT)''');
        await db.execute('''CREATE TABLE item_history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          action TEXT,
          date TEXT,
          detail TEXT)''');
      },
    );
  }

  static Future<void> insertItem(Item item) async {
    final dbClient = await db;
    await dbClient.insert('items', item.toMap());
    await logHistory(item.name, 'Added', 'Qty: ${item.quantity}, Price: ${item.price}');
  }

  static Future<void> deleteItem(int id, String name) async {
    final dbClient = await db;
    await dbClient.delete('items', where: 'id = ?', whereArgs: [id]);
    await logHistory(name, 'Deleted', '');
  }

  static Future<void> updateItem(Item item) async {
    final dbClient = await db;
    await dbClient.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  static Future<List<Item>> fetchItems({String sortBy = 'name'}) async {
    final dbClient = await db;

    String orderByColumn = 'name';
    String order = 'ASC';

    if (sortBy == 'price_asc') {
      orderByColumn = 'price';
      order = 'ASC';
    } else if (sortBy == 'price_desc') {
      orderByColumn = 'price';
      order = 'DESC';
    } else if (sortBy == 'category') {
      orderByColumn = 'category';
    }

    final List<Map<String, dynamic>> maps = await dbClient.query(
      'items',
      orderBy: '$orderByColumn $order',
    );

    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  static Future<void> insertSoldItem(SoldItem item) async {
    final dbClient = await db;
    await dbClient.insert('sold_items', item.toMap());
    await logHistory(item.name, 'Sold', 'Sold Price: ${item.sellPrice}');
  }

  static Future<List<SoldItem>> fetchSoldItems() async {
    final dbClient = await db;
    final maps = await dbClient.query('sold_items', orderBy: 'date DESC');
    return maps.map((map) => SoldItem.fromMap(map)).toList();
  }

  // ------------- NEW: History
  static Future<void> logHistory(String name, String action, String detail) async {
    final dbClient = await db;
    await dbClient.insert('item_history', {
      'name': name,
      'action': action,
      'date': DateTime.now().toString(),
      'detail': detail,
    });
  }

  static Future<List<ItemHistory>> fetchItemHistory() async {
    final dbClient = await db;
    final maps = await dbClient.query('item_history', orderBy: 'date DESC');
    return maps.map((map) => ItemHistory.fromMap(map)).toList();
  }
}
