import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'EmployeeCarsScreen.dart';
import 'EmployeeRentalsScreen.dart';
import 'customer_list_screen.dart';
import 'employee_dashboard_screen.dart';
import 'EmployeeProfileScreen.dart';
import 'car_list_screen.dart';

const kBurgundy = Color(0xFF800020);

class EmployeeDrawer extends StatefulWidget {
  final String current;
  final String? employeeName;
  final String? employeeImageUrl;

  const EmployeeDrawer({
    super.key,
    required this.current,
    this.employeeName,
    this.employeeImageUrl,
  });

  @override
  State<EmployeeDrawer> createState() => _EmployeeDrawerState();
}

class _EmployeeDrawerState extends State<EmployeeDrawer> {
  late String employeeName;
  late String employeeImageUrl;

  @override
  void initState() {
    super.initState();
    employeeName = widget.employeeName ?? "";
    employeeImageUrl = widget.employeeImageUrl ?? "";
    _loadEmployeeInfoIfNeeded();
  }

  Future<void> _loadEmployeeInfoIfNeeded() async {
    if (employeeName.isNotEmpty && employeeImageUrl.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString("employee_name") ?? "";
    final imageName = prefs.getString("employee_imageName") ?? "";

    String url = employeeImageUrl;
    if (url.isEmpty && imageName.isNotEmpty) {
      url = "http://10.0.2.2/car_rental_backend/api/uploads/$imageName";
    }

    if (!mounted) return;
    setState(() {
      if (employeeName.isEmpty) employeeName = name;
      if (employeeImageUrl.isEmpty) employeeImageUrl = url;
    });
  }

  // ==================== Navigation ====================
  void _goDashboard(BuildContext context) {
    Navigator.pop(context);
    if (widget.current == "dashboard") return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeDashboardScreen(
          employeeName: employeeName,
          employeeImageUrl: employeeImageUrl,
        ),
      ),
    );
  }

  void _goCars(BuildContext context) {
    Navigator.pop(context);
    if (widget.current == "cars") return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeCarsScreen(
          employeeName: employeeName,
          employeeImageUrl: employeeImageUrl,
        ),
      ),
    );
  }

  void _goRentals(BuildContext context) {
    Navigator.pop(context);
    if (widget.current == "rentals") return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeRentalsScreen(
          employeeName: employeeName,
          employeeImageUrl: employeeImageUrl,
        ),
      ),
    );
  }

  void _goCustomers(BuildContext context) {
    Navigator.pop(context);
    if (widget.current == "customers") return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerListScreen(
          employeeName: employeeName,
          employeeImageUrl: employeeImageUrl,
        ),
      ),
    );
  }

  void _goProfile(BuildContext context) {
    Navigator.pop(context);
    if (widget.current == "profile") return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    Navigator.pop(context);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CarListScreen()),
      (route) => false,
    );
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(22)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            InkWell(
              onTap: () => _goProfile(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _EmployeeAvatar(
                        name: employeeName, imageUrl: employeeImageUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employeeName.isEmpty ? "Employee" : employeeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "View profile",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            _item(
              icon: Icons.dashboard,
              text: "Dashboard",
              active: widget.current == "dashboard",
              onTap: () => _goDashboard(context),
            ),
            _item(
              icon: Icons.directions_car,
              text: "Cars",
              active: widget.current == "cars",
              onTap: () => _goCars(context),
            ),
            _item(
              icon: Icons.history,
              text: "Rented Cars",
              active: widget.current == "rentals",
              onTap: () => _goRentals(context),
            ),
            _item(
              icon: Icons.people,
              text: "Customers",
              active: widget.current == "customers",
              onTap: () => _goCustomers(context),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                "Sign Out",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String text,
    required bool active,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: active ? kBurgundy : null),
      title: Text(
        text,
        style: TextStyle(
          color: active ? kBurgundy : null,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: active,
      onTap: onTap,
    );
  }
}

class _EmployeeAvatar extends StatelessWidget {
  final String name;
  final String imageUrl;

  const _EmployeeAvatar({required this.name, required this.imageUrl});

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return "?";
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.black12,
      child: ClipOval(
        child: imageUrl.isEmpty
            ? Center(
                child: Text(
                  _initials(name.isEmpty ? "E" : name),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            : Image.network(
                imageUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    _initials(name.isEmpty ? "E" : name),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
      ),
    );
  }
}
