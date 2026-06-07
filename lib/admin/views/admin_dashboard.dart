import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: const [
          _Card(title: "Revenue", value: "\$0"),
          _Card(title: "Orders", value: "0"),
          _Card(title: "Delivered", value: "0"),
          _Card(title: "Products", value: "0"),
          _Card(title: "Low Stock", value: "0"),
          _Card(title: "Out of Stock", value: "0"),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String value;

  const _Card({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
