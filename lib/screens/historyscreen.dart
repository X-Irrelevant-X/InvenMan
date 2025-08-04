import 'package:flutter/material.dart';
import 'package:invenman/db.dart';
import 'package:invenman/models/item_history.dart';

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
            return ListTile(
              title: Text("${item.name} - ${item.action}"),
              subtitle: Text("${item.detail}\n${item.date}"),
            );
          },
        );
      },
    );
  }
}
