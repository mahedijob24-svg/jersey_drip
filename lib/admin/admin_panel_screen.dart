import 'package:flutter/material.dart';
import 'views/admin_dashboard.dart';
import 'views/admin_inventory.dart';
import 'views/admin_orders.dart';
import 'views/admin_products.dart';
import 'views/admin_users.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int index = 0;

  late final List<Widget> pages = [
    AdminDashboard(onNavigate: _navigateToSection),
    const AdminOrders(),
    const AdminProducts(),
    const AdminInventory(),
    const AdminUsers(),
  ];

  final titles = const [
    "Dashboard",
    "Orders",
    "Products",
    "Inventory",
    "Users",
  ];

  void _navigateToSection(int sectionIndex) {
    setState(() => index = sectionIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin - ${titles[index]}"),
        backgroundColor: Colors.indigo,
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (i) {
                setState(() => index = i);
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text("Dashboard"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.list_alt),
                  label: Text("Orders"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory),
                  label: Text("Products"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.view_list),
                  label: Text("Inventory"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text("Users"),
                ),
              ],
            ),
          Expanded(child: pages[index]),
        ],
      ),
      bottomNavigationBar: !isWide
          ? BottomNavigationBar(
              currentIndex: index,
              onTap: (i) => setState(() => index = i),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: "Dashboard",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: "Orders",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory),
                  label: "Products",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.view_list),
                  label: "Inventory",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: "Users",
                ),
              ],
            )
          : null,
    );
  }
}
