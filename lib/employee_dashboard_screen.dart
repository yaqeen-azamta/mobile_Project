import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import 'employee_drawer.dart';

const kBurgundy = Color(0xFF800020);

class EmployeeDashboardScreen extends StatefulWidget {
  final String employeeName;
  final String employeeImageUrl;

  const EmployeeDashboardScreen({
    super.key,
    required this.employeeName,
    required this.employeeImageUrl,
  });

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  bool loading = true;
  String? error;

  Map<String, dynamic>? data;

  static const String apiUrl =
      "http://10.0.2.2/car_rental_backend/api/employee_dashboard.php";

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await http.get(Uri.parse(apiUrl));
      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}");
      }

      final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
      if (jsonMap["success"] != true) {
        throw Exception(jsonMap["message"] ?? "Failed");
      }

      setState(() => data = (jsonMap["data"] as Map<String, dynamic>));
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  // ===================== UI pieces =====================

  Widget _kpiCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                  Text(title,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineRentals7(List items) {
    final Map<String, int> map = {};
    for (final it in items) {
      map[it["day"].toString()] = int.tryParse(it["count"].toString()) ?? 0;
    }

    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final key =
          "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      return key;
    });

    final spots = <FlSpot>[];
    for (int i = 0; i < days.length; i++) {
      final c = map[days[i]] ?? 0;
      spots.add(FlSpot(i.toDouble(), c.toDouble()));
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Rentals (Last 7 Days)",
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 28),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= days.length) {
                            return const SizedBox.shrink();
                          }
                          final dd = days[idx].substring(8, 10);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child:
                                Text(dd, style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pieCarsStatus(Map<String, dynamic> carsStatus) {
    final total = int.tryParse(carsStatus["total_cars"].toString()) ?? 0;
    final rented = int.tryParse(carsStatus["rented_now"].toString()) ?? 0;
    final available = int.tryParse(carsStatus["available_now"].toString()) ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Cars Now",
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 36,
                        sectionsSpace: 2,
                        sections: [
                          PieChartSectionData(
                            value: available.toDouble(),
                            title: "Available\n$available",
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          PieChartSectionData(
                            value: rented.toDouble(),
                            title: "Rented\n$rented",
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total: $total",
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text("Available: $available",
                            style: const TextStyle(color: Colors.black54)),
                        Text("Rented: $rented",
                            style: const TextStyle(color: Colors.black54)),
                      ],
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

  Widget _barTopCars(List items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final values =
        items.map((e) => int.tryParse(e["count"].toString()) ?? 0).toList();
    final maxY = (values.isEmpty ? 5 : values.reduce((a, b) => a > b ? a : b))
        .toDouble()
        .clamp(5, 100000);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Top Cars (Most Rented)",
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY + 1,
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 28),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= items.length) {
                            return const SizedBox.shrink();
                          }
                          final name = items[idx]["car_name"].toString();
                          // اختصار الاسم
                          final short = name.length > 10
                              ? "${name.substring(0, 10)}…"
                              : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(short,
                                style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: List.generate(items.length, (i) {
                    final y = int.tryParse(items[i]["count"].toString()) ?? 0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [BarChartRodData(toY: y.toDouble(), width: 14)],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topCustomersList(List items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Top Customers",
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...items.map((e) {
              final name = e["full_name"].toString();
              final count = e["count"].toString();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text("$count rentals",
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ===================== Build =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      drawer: EmployeeDrawer(
        employeeName: widget.employeeName,
        employeeImageUrl: widget.employeeImageUrl,
        current: "dashboard",
      ),
      appBar: AppBar(
        title: const Text("Employee Dashboard"),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.black12,
              child: ClipOval(
                child: widget.employeeImageUrl.isEmpty
                    ? const Icon(Icons.person)
                    : Image.network(
                        widget.employeeImageUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person),
                      ),
              ),
            ),
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text("Error: $error"))
              : RefreshIndicator(
                  onRefresh: fetchDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      // KPIs
                      Builder(builder: (_) {
                        final kpis =
                            (data?["kpis"] ?? {}) as Map<String, dynamic>;
                        final activeNow = (int.tryParse(
                                    kpis["active_rentals_now"].toString()) ??
                                0)
                            .toString();
                        final totalRentals =
                            (int.tryParse(kpis["total_rentals"].toString()) ??
                                    0)
                                .toString();
                        final totalCustomers =
                            (int.tryParse(kpis["total_customers"].toString()) ??
                                    0)
                                .toString();

                        return Column(
                          children: [
                            _kpiCard("Active rentals now", activeNow,
                                Icons.timelapse),
                            _kpiCard(
                                "Total rentals", totalRentals, Icons.history),
                            _kpiCard("Total customers", totalCustomers,
                                Icons.people),
                          ],
                        );
                      }),

                      const SizedBox(height: 10),
                      _lineRentals7(
                          (data?["rentals_last_7_days"] ?? []) as List),

                      const SizedBox(height: 10),
                      _pieCarsStatus(
                          (data?["cars_status"] ?? {}) as Map<String, dynamic>),

                      const SizedBox(height: 10),
                      _barTopCars((data?["top_cars"] ?? []) as List),

                      const SizedBox(height: 10),
                      _topCustomersList((data?["top_customers"] ?? []) as List),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
