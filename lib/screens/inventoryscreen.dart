import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ivenman/db.dart';
import 'package:ivenman/models/items.dart';
import 'package:ivenman/models/sold_items.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String sortBy = 'name';

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
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: "Category")),
              TextField(controller: quantityController, decoration: const InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final item = Item(
                name: nameController.text,
                description: descController.text,
                price: double.parse(priceController.text),
                category: categoryController.text,
                quantity: int.parse(quantityController.text),
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
              final sellPrice = double.parse(sellController.text);
              if (item.quantity > 0) {
                item.quantity -= 1;
                await DBHelper.updateItem(item);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<String>(
          value: sortBy,
          onChanged: (value) => setState(() => sortBy = value!),
          items: const [
            DropdownMenuItem(value: 'name', child: Text("Name")),
            DropdownMenuItem(value: 'price_asc', child: Text("Price: Low to High")),
            DropdownMenuItem(value: 'price_desc', child: Text("Price: High to Low")),
            DropdownMenuItem(value: 'category', child: Text("Category")),
          ],
        ),
        Expanded(
          child: FutureBuilder<List<Item>>(
            future: DBHelper.fetchItems(sortBy: sortBy),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final items = snapshot.data!;
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return ListTile(
                    title: Text("${item.name} (\$${item.price})"),
                    subtitle: Text("Qty: ${item.quantity}, Category: ${item.category}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.sell),
                      onPressed: () => _sellItem(item),
                    ),
                    onLongPress: () async {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Delete Item"),
                            content: Text("Are you sure you want to delete '${item.name}'?"),
                            actions: [
                              TextButton(
                                child: const Text("Cancel"),
                                onPressed: () => Navigator.of(context).pop(false),
                              ),
                              TextButton(
                                child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                onPressed: () => Navigator.of(context).pop(true),
                              ),
                            ],
                          );
                        },
                      );

                      if (shouldDelete == true) {
                        await DBHelper.deleteItem(item.id!);
                        setState(() {});
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton.extended(
            onPressed: _showAddItemDialog,
            label: const Text("Add Item"),
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
