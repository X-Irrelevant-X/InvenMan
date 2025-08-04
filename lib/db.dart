import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:invenman/models/items.dart';
import 'package:invenman/models/sold_items.dart';
import 'package:invenman/models/item_history.dart';

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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            description TEXT,
            price REAL,
            category TEXT,
            quantity INTEGER,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE sold_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            costPrice REAL,
            sellPrice REAL,
            date TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE item_history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            action TEXT,
            date TEXT,
            detail TEXT
          )
        ''');
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE items ADD COLUMN createdAt TEXT');
          await db.execute('ALTER TABLE items ADD COLUMN updatedAt TEXT');
        }
      },
    );
  }

  static Future<void> insertItem(Item item) async {
    final dbClient = await db;
    await dbClient.insert('items', item.toJson()); // uses toJson for timestamps
    await logHistory(item.name, 'Added', 'Qty: ${item.quantity}, Price: ${item.price}');
  }

  static Future<void> updateItem(Item item) async {
    final dbClient = await db;
    await dbClient.update(
      'items',
      item.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    await logHistory(item.name, 'Edited', 'Qty: ${item.quantity}, Price: ${item.price}');
  }

  static Future<void> deleteItem(int id, String name) async {
    final dbClient = await db;
    await dbClient.delete('items', where: 'id = ?', whereArgs: [id]);
    await logHistory(name, 'Deleted', '');
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

    return List.generate(maps.length, (i) => Item.fromJson(maps[i]));
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

  static Future<void> logHistory(String name, String action, String detail) async {
    final dbClient = await db;
    await dbClient.insert('item_history', {
      'name': name,
      'action': action,
      'date': DateTime.now().toIso8601String(),
      'detail': detail,
    });
  }

  static Future<List<ItemHistory>> fetchItemHistory() async {
    final dbClient = await db;
    final maps = await dbClient.query('item_history', orderBy: 'date DESC');
    return maps.map((map) => ItemHistory.fromMap(map)).toList();
  }
}
