import 'package:flutter/material.dart';
import 'package:invenman/db.dart';
import 'package:invenman/models/item_history.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ItemHistory>>(
      future: DBHelper.fetchItemHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final history = snapshot.data!;
        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (_, i) {
            final item = history[i];

            // Format date
            String formattedDate = DateFormat('h:mm a, d MMMM, y').format(DateTime.parse(item.date));

            // Initialize variables
            double? costPrice;
            double? soldPrice;

            // If Added → extract Price as costPrice
            if (item.action == 'Added') {
              final priceMatch = RegExp(r'Price:\s*([\d.]+)').firstMatch(item.detail);
              if (priceMatch != null) {
                costPrice = double.parse(priceMatch.group(1)!);
              }
            }

            // If Sold → extract Sold Price
            if (item.action == 'Sold') {
              final soldMatch = RegExp(r'Sold Price:\s*([\d.]+)').firstMatch(item.detail);
              if (soldMatch != null) {
                soldPrice = double.parse(soldMatch.group(1)!);
              }

              // Now try to find last cost price for this item
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

            // For Edited: highlight what's updated
            String editedText = '';
            if (item.action == 'Edited') {
              // Example detail: "Old Price: 5.00 → New Price: 6.00"
              editedText = item.detail;
            }

            // Build Profit/Loss text
            String profitLossText = '';
            if (costPrice != null && soldPrice != null) {
              final profit = soldPrice - costPrice;
              profitLossText = '${profit >= 0 ? 'Profit' : 'Loss'}: \$${profit.toStringAsFixed(2)}';
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${item.name} - ${item.action}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.detail,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      if (profitLossText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          profitLossText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: profitLossText.contains('Profit') ? Colors.green : Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
