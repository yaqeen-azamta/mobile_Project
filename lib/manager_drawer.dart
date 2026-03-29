import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'manager_dashboard_screen.dart';
import 'cars_screen.dart';
import 'bookings_screen.dart';
import 'employees_screen.dart';
import 'car_list_screen.dart';

const kBurgundy = Color(0xFF800020);

class ManagerDrawer extends StatelessWidget {
  final String current;

  const ManagerDrawer({super.key, required this.current});

  void _go(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  Widget _item({
    required BuildContext context,
    required String id,
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    final selected = current == id;
    return ListTile(
      leading: Icon(icon, color: selected ? kBurgundy : Colors.black54),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
          color: selected ? kBurgundy : Colors.black87,
        ),
      ),
      selected: selected,
      selectedTileColor: kBurgundy.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => _go(context, page),
    );
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CarListScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // ================= Header =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kBurgundy,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Manager Panel",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Inventory • Bookings • Reports",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ================= Menu Items =================
              _item(
                context: context,
                id: "dashboard",
                icon: Icons.dashboard_rounded,
                title: "Dashboard",
                page: const ManagerDashboardScreen(),
              ),

              _item(
                context: context,
                id: "cars",
                icon: Icons.car_rental,
                title: "Cars Management",
                page: const CarsScreen(),
              ),

              _item(
                context: context,
                id: "bookings",
                icon: Icons.event_note,
                title: "Bookings Management",
                page: const BookingsScreen(),
              ),

              _item(
                context: context,
                id: "employees",
                icon: Icons.groups,
                title: "Employees",
                page: EmployeesScreen(),
              ),

              const Spacer(),
              const Divider(),

              // ================= Logout =================
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.red,
                  ),
                ),
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
