import 'package:flutter/material.dart';
import 'package:invenman/db.dart';
import 'package:invenman/models/items.dart';
import 'package:invenman/models/item_history.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ItemHistory>>(
      future: DBHelper.fetchItemHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = snapshot.data!;

        return FutureBuilder<List<Item>>(
          future: DBHelper.fetchItems(),
          builder: (context, itemSnapshot) {
            if (!itemSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = itemSnapshot.data!;
            final itemMap = {for (var item in items) item.name: item.category};

            return ListView.builder(
              itemCount: history.length,
              itemBuilder: (_, i) {
                final item = history[i];
                final category = itemMap[item.name] ?? 'Uncategorized';
                String formattedDate =
                    DateFormat('h:mm a, d MMMM, y').format(DateTime.parse(item.date));

                double? costPrice;
                double? soldPrice;

                if (item.action == 'Added') {
                  final priceMatch = RegExp(r'Price:\s*([\d.]+)').firstMatch(item.detail);
                  if (priceMatch != null) {
                    costPrice = double.parse(priceMatch.group(1)!);
                  }
                }

                if (item.action == 'Sold') {
                  final soldMatch = RegExp(r'Sold Price:\s*([\d.]+)').firstMatch(item.detail);
                  if (soldMatch != null) {
                    soldPrice = double.parse(soldMatch.group(1)!);
                  }
                  for (int j = i + 1; j < history.length; j++) {
                    final prev = history[j];
                    if (prev.name == item.name && prev.action == 'Added') {
                      final prevPriceMatch = RegExp(r'Price:\s*([\d.]+)').firstMatch(prev.detail);
                      if (prevPriceMatch != null) {
                        costPrice = double.parse(prevPriceMatch.group(1)!);
                        break;
                      }
                    }
                  }
                }

                String profitLossText = '';
                if (costPrice != null && soldPrice != null) {
                  final profit = soldPrice - costPrice;
                  profitLossText = '${profit >= 0 ? 'Profit' : 'Loss'}: \$${profit.toStringAsFixed(2)}';
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.deepPurple.shade300,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "${item.name} - ${item.action}",
                                  style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  item.detail,
                                  style: const TextStyle(fontSize: 20, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(fontSize: 20, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (profitLossText.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    profitLossText,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: profitLossText.contains('Profit')
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
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
        );
      },
    );
  }
}