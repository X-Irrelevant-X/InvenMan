import 'package:flutter/material.dart';
import 'package:ivenman/db.dart';
import 'package:ivenman/models/sold_items.dart';

class SoldItemsPage extends StatelessWidget {
  const SoldItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SoldItem>>(
      future: DBHelper.fetchSoldItems(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            final profit = item.sellPrice - item.costPrice;
            return ListTile(
              title: Text("${item.name} - ${item.date}"),
              subtitle: Text(
                  "Cost: \$${item.costPrice} | Sold: \$${item.sellPrice} | ${profit >= 0 ? 'Profit' : 'Loss'}: \$${profit.toStringAsFixed(2)}"),
            );
          },
        );
      },
    );
  }
}
