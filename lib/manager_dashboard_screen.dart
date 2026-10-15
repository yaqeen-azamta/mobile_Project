import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dashboard_stats.dart';
import 'cars_screen.dart';
import 'bookings_screen.dart';
import 'employees_screen.dart';
import 'revenue_screen.dart';
import 'manager_drawer.dart';

const kBurgundy = Color(0xFF800020);

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  late Future<DashboardStats> _statsFuture;
  String _revenuePeriod = 'month';

  static const String _dashboardUrl =
      'http://10.0.2.2/car_rental_backend/api/dashboard.php';

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchDashboard();
  }

  Future<DashboardStats> _fetchDashboard() async {
    final res = await http.get(Uri.parse(_dashboardUrl));

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = json.decode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception("Invalid dashboard response");
    }

    return DashboardStats.fromJson(decoded);
  }

  Future<void> _refresh() async {
    setState(() {
      _statsFuture = _fetchDashboard();
    });
    await _statsFuture;
  }

  Future<void> _openCars() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CarsScreen()),
    );
    if (changed == true) await _refresh();
  }

  Future<void> _openBookings() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BookingsScreen()),
    );
    if (changed == true) await _refresh();
  }

  Future<void> _openEmployees() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EmployeesScreen()),
    );
    if (changed == true) await _refresh();
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: kBurgundy.withOpacity(0.12),
              child: Icon(icon, color: kBurgundy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: kBurgundy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manager Dashboard"),
        backgroundColor: kBurgundy,
        foregroundColor: Colors.white,
      ),
      drawer: const ManagerDrawer(current: "dashboard"),
      body: FutureBuilder<DashboardStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final s = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _kpiCard(
                  title: "Pending rentals",
                  value: s.pendingRentals.toString(),
                  icon: Icons.pending_actions,
                ),
                _kpiCard(
                  title: "Active rentals",
                  value: s.activeRentals.toString(),
                  icon: Icons.directions_car,
                ),
                _kpiCard(
                  title: "Available cars",
                  value: s.availableCars.toString(),
                  icon: Icons.car_rental,
                ),

                /// Revenue Card
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RevenueScreen(
                        initialPeriod: _revenuePeriod,
                      ),
                    ),
                  ),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: kBurgundy.withOpacity(0.12),
                            child: const Icon(Icons.attach_money,
                                color: kBurgundy),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Revenue",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${s.revenue.toStringAsFixed(2)} ₪",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownButton<String>(
                            value: _revenuePeriod,
                            items: const [
                              DropdownMenuItem(
                                  value: 'day', child: Text('Day')),
                              DropdownMenuItem(
                                  value: 'week', child: Text('Week')),
                              DropdownMenuItem(
                                  value: 'month', child: Text('Month')),
                              DropdownMenuItem(
                                  value: 'year', child: Text('Year')),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                _revenuePeriod = v;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                _actionButton(
                  title: "Manage Cars",
                  icon: Icons.car_rental,
                  onTap: _openCars,
                ),
                const SizedBox(height: 10),
                _actionButton(
                  title: "Manage Bookings",
                  icon: Icons.event_note,
                  onTap: _openBookings,
                ),
                const SizedBox(height: 10),
                _actionButton(
                  title: "Manage Employees",
                  icon: Icons.badge,
                  onTap: _openEmployees,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
