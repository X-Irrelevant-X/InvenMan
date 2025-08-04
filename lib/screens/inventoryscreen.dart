import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invenman/db.dart';
import 'package:invenman/models/items.dart';
import 'package:invenman/models/sold_items.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String sortBy = 'name';

  final DateFormat dateFormat = DateFormat('h.mma, d MMMM, yyyy');

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Add New Item"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: "Category"),
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final item = Item(
                name: nameController.text.trim(),
                description: descController.text.trim(),
                price: double.parse(priceController.text.trim()),
                category: categoryController.text.trim(),
                quantity: int.parse(quantityController.text.trim()),
                createdAt: DateTime.now(),
                updatedAt: null,
              );
              await DBHelper.insertItem(item);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  void _showEditItemDialog(Item item) {
    final descController = TextEditingController(text: item.description);
    final priceController = TextEditingController(text: item.price.toString());
    final quantityController = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Edit Item"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // Name and category shown but disabled
              TextField(
                controller: TextEditingController(text: item.name),
                decoration: const InputDecoration(labelText: "Name"),
                enabled: false,
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: TextEditingController(text: item.category),
                decoration: const InputDecoration(labelText: "Category"),
                enabled: false,
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final updatedItem = Item(
                id: item.id,
                name: item.name,
                description: descController.text.trim(),
                price: item.price,
                category: item.category,
                quantity: int.parse(quantityController.text.trim()),
                createdAt: item.createdAt,
                updatedAt: DateTime.now(),
              );
              await DBHelper.updateItem(updatedItem);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }

  Future<void> _sellItem(Item item) async {
    final sellController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("Sell ${item.name}"),
        content: TextField(
          controller: sellController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Selling Price"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final sellPrice = double.parse(sellController.text.trim());
              if (item.quantity > 0) {
                final updatedItem = Item(
                  id: item.id,
                  name: item.name,
                  description: item.description,
                  price: item.price,
                  category: item.category,
                  quantity: item.quantity - 1,
                  createdAt: item.createdAt,
                  updatedAt: DateTime.now(),
                );
                await DBHelper.updateItem(updatedItem);
                await DBHelper.insertSoldItem(SoldItem(
                  name: item.name,
                  costPrice: item.price,
                  sellPrice: sellPrice,
                  date: DateFormat.yMd().add_jm().format(DateTime.now()),
                ));
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Confirm"),
          )
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    String formatted = DateFormat('h.m').format(date).toLowerCase();
    String ampm = DateFormat('a').format(date).toLowerCase();
    String dayMonthYear = DateFormat('d MMMM, yyyy').format(date);
    return '$formatted$ampm, $dayMonthYear';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: sortBy,
                  onChanged: (value) => setState(() => sortBy = value!),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text("Name")),
                    DropdownMenuItem(value: 'price_asc', child: Text("Price: Low to High")),
                    DropdownMenuItem(value: 'price_desc', child: Text("Price: High to Low")),
                    DropdownMenuItem(value: 'category', child: Text("Category")),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showAddItemDialog,
                icon: const Icon(Icons.add),
                label: const Text("Add Item"),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Item>>(
            future: DBHelper.fetchItems(sortBy: sortBy),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const Center(child: Text('No items found.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onLongPress: () async {
                        final action = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Choose Action"),
                            actions: [
                              TextButton(
                                child: const Text("Edit"),
                                onPressed: () => Navigator.pop(context, 'edit'),
                              ),
                              TextButton(
                                child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                onPressed: () => Navigator.pop(context, 'delete'),
                              ),
                            ],
                          ),
                        );

                        if (action == 'edit') {
                          _showEditItemDialog(item);
                        } else if (action == 'delete') {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Item"),
                              content: Text("Are you sure to delete '${item.name}'?"),
                              actions: [
                                TextButton(
                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                                TextButton(
                                  child: const Text("Cancel"),
                                  onPressed: () => Navigator.pop(context, false),
                                ),
                              ],
                            ),
                          );
                          if (shouldDelete == true) {
                            await DBHelper.deleteItem(item.id!, item.name);
                            if (!mounted) return;
                            setState(() {});
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.category,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple.shade300,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.description,
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.normal,
                                color: Color.fromARGB(206, 255, 236, 236),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Price: \$${item.price.toStringAsFixed(2)}",
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 24),
                                Text(
                                  "Qty: ${item.quantity}",
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(color: Colors.deepPurple.shade100),
                            const SizedBox(height: 6),
                            Text(
                              "Added: ${_formatDate(item.createdAt)}",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            if (item.updatedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Edited: ${_formatDate(item.updatedAt!)}",
                                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                            ],
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _sellItem(item),
                              icon: const Icon(Icons.sell),
                              label: const Text("Sell One"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
