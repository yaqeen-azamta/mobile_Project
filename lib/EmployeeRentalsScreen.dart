import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'employee_drawer.dart';

const kBurgundy = Color(0xFF800020);
const kBlack = Colors.black;

class RentalCardModel {
  final int rentalId;
  final String carName;
  final String customerName;
  final String startDate;
  final String endDate;
  final String imageUrl;
  final String status;

  final DateTime? start;
  final DateTime? end;

  RentalCardModel({
    required this.rentalId,
    required this.carName,
    required this.customerName,
    required this.startDate,
    required this.endDate,
    required this.imageUrl,
    required this.status,
    required this.start,
    required this.end,
  });
  static DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    final v = s.trim().replaceAll('/', '-');
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }

  factory RentalCardModel.fromJson(Map<String, dynamic> json) {
    final s = (json['start_date'] ?? '').toString();
    final e = (json['end_date'] ?? '').toString();

    return RentalCardModel(
      rentalId: int.parse(json['rental_id'].toString()),
      carName: (json['car_name'] ?? '').toString(),
      customerName: (json['customer_name'] ?? '').toString(),
      startDate: s,
      endDate: e,
      imageUrl: (json['image_url'] ?? '').toString(),
      status: (json['rental_status'] ?? 'PENDING').toString(),
      start: _parseDate(s),
      end: _parseDate(e),
    );
  }
}

class EmployeeRentalsScreen extends StatefulWidget {
  final String employeeName;
  final String employeeImageUrl;

  const EmployeeRentalsScreen({
    super.key,
    required this.employeeName,
    required this.employeeImageUrl,
  });

  @override
  State<EmployeeRentalsScreen> createState() => _EmployeeRentalsScreenState();
}

class _EmployeeRentalsScreenState extends State<EmployeeRentalsScreen> {
  late Future<List<RentalCardModel>> _future;
  final TextEditingController _searchCtrl = TextEditingController();

  DateTime? filterStartFrom;
  DateTime? filterEndTo;

  @override
  void initState() {
    super.initState();
    _future = fetchRentals();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<RentalCardModel>> fetchRentals() async {
    final url = Uri.parse(
      "http://10.0.2.2/car_rental_backend/api/employee_rentals.php",
    );
    final res = await http.get(url);
    final data = jsonDecode(res.body);

    if (data["success"] != true) {
      throw Exception(data["message"] ?? "Failed to load rentals");
    }

    final List items = data["data"] ?? [];
    return items.map((e) => RentalCardModel.fromJson(e)).toList();
  }

  Future<void> _handleRentalAction(int rentalId, String action) async {
    final url = Uri.parse(
      "http://10.0.2.2/car_rental_backend/api/approve_rental.php",
    );

    final body = Uri(
      queryParameters: {
        "rental_id": rentalId.toString(),
        "action": action,
      },
    ).query;

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: body,
    );

    debugPrint("RAW RESPONSE:");
    debugPrint(res.body);

    try {
      final data = jsonDecode(res.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Action completed")),
      );

      setState(() {
        _future = fetchRentals();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid server response")),
      );
    }
  }

  List<RentalCardModel> filteredRentals(List<RentalCardModel> rentals) {
    final q = _searchCtrl.text.trim().toLowerCase();

    return rentals.where((r) {
      final customer = r.customerName.toLowerCase();
      final car = r.carName.toLowerCase();
      final searchMatch = q.isEmpty || customer.contains(q) || car.contains(q);

      bool startMatch = true;
      if (filterStartFrom != null) {
        final rs = r.start;
        if (rs == null) return false;
        startMatch = !rs.isBefore(filterStartFrom!);
      }

      bool endMatch = true;
      if (filterEndTo != null) {
        final re = r.end;
        if (re == null) return false;
        endMatch = !re.isAfter(filterEndTo!);
      }

      return searchMatch && startMatch && endMatch;
    }).toList();
  }

  // =======================
  // UI
  // =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      drawer: EmployeeDrawer(
        employeeName: widget.employeeName,
        employeeImageUrl: widget.employeeImageUrl,
        current: "rentals",
      ),
      appBar: AppBar(
        title: const Text("Rented Cars History"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<RentalCardModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          final rentals = snap.data ?? [];
          final filtered = filteredRentals(rentals);

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, i) => RentalCard(
              item: filtered[i],
              onApprove: () =>
                  _handleRentalAction(filtered[i].rentalId, "approve"),
              onReject: () =>
                  _handleRentalAction(filtered[i].rentalId, "reject"),
            ),
          );
        },
      ),
    );
  }
}

// -------------------- CARD --------------------
class RentalCard extends StatelessWidget {
  final RentalCardModel item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const RentalCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = item.status == "PENDING";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          ListTile(
            title: Text(
              item.carName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Customer: ${item.customerName}"),
                Text("From: ${item.startDate}"),
                Text("To: ${item.endDate}"),
                const SizedBox(height: 4),
                Text(
                  "Status: ${item.status}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.status == "ACTIVE"
                        ? Colors.green
                        : item.status == "CANCELLED"
                            ? Colors.red
                            : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          if (isPending) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text("Reject"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Approve"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
