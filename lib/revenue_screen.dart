import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const kBurgundy = Color(0xFF800020);

class RevenueScreen extends StatefulWidget {
  final String initialPeriod;
  const RevenueScreen({super.key, this.initialPeriod = 'month'});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  late String _period;
  late Future<Map<String, dynamic>> _future;

  static const String _baseUrl =
      "http://10.0.2.2/car_rental_backend/api/revenue.php";

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    _future = _getRevenue();
  }

  Future<Map<String, dynamic>> _getRevenue() async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      "period": _period,
    });

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}");
    }

    final decoded = json.decode(res.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception("Invalid JSON response");
    }

    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? "Revenue failed");
    }

    return decoded;
  }

  void _reload() {
    setState(() {
      _future = _getRevenue();
    });
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900)),
      );

  String _lineTitle() {
    switch (_period) {
      case 'day':
        return 'Daily revenue';
      case 'week':
        return 'Weekly revenue';
      case 'year':
        return 'Yearly revenue';
      default:
        return 'Monthly revenue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Revenue"),
        backgroundColor: kBurgundy,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text("Period: "),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _period,
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('Day')),
                    DropdownMenuItem(value: 'week', child: Text('Week')),
                    DropdownMenuItem(value: 'month', child: Text('Month')),
                    DropdownMenuItem(value: 'year', child: Text('Year')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _period = v;
                      _future = _getRevenue();
                    });
                  },
                ),
                const Spacer(),
                IconButton(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final data = snapshot.data!;

                final byPayment =
                    Map<String, dynamic>.from(data['by_payment'] ?? {});
                final byStatus =
                    Map<String, dynamic>.from(data['by_status'] ?? {});
                final byCar =
                    List<Map<String, dynamic>>.from(data['by_car'] ?? []);
                final daily =
                    List<Map<String, dynamic>>.from(data['daily'] ?? []);

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _sectionTitle("Revenue by payment"),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text("CASH"),
                            trailing: Text(
                                "${(byPayment['cash'] ?? 0).toDouble()} ₪"),
                          ),
                          ListTile(
                            title: const Text("WALLET"),
                            trailing: Text(
                                "${(byPayment['wallet'] ?? 0).toDouble()} ₪"),
                          ),
                        ],
                      ),
                    ),
                    _sectionTitle("Revenue by status"),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text("ACTIVE"),
                            trailing: Text(
                                "${(byStatus['active'] ?? 0).toDouble()} ₪"),
                          ),
                          ListTile(
                            title: const Text("COMPLETED"),
                            trailing: Text(
                                "${(byStatus['completed'] ?? 0).toDouble()} ₪"),
                          ),
                        ],
                      ),
                    ),
                    _sectionTitle("Top earning cars"),
                    Card(
                      child: Column(
                        children: byCar
                            .take(5)
                            .map(
                              (c) => ListTile(
                                title: Text(c['car_name'] ?? ''),
                                trailing:
                                    Text("${(c['revenue'] ?? 0).toDouble()} ₪"),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    _sectionTitle(_lineTitle()),
                    Card(
                      child: SizedBox(
                        height: 140,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _SimpleLineChart(data: daily),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- Simple Line Chart ---------------- */

class _SimpleLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _SimpleLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final values = data.map((e) => (e['revenue'] ?? 0).toDouble()).toList();

    return CustomPaint(
      painter: _LinePainter(values.cast<double>()),
      child: Container(),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  _LinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = kBurgundy
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    final step = size.width / (values.length - 1);

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = step * i;
      final y = size.height - ((values[i] - minV) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
