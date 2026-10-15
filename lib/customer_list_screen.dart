import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'employee_drawer.dart';

class CustomerListScreen extends StatefulWidget {
  final String employeeName;
  final String employeeImageUrl;

  const CustomerListScreen({
    super.key,
    required this.employeeName,
    required this.employeeImageUrl,
  });

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> customers = [];

  static const String apiUrl =
      "http://10.0.2.2/car_rental_backend/api/customers.php";

  static const String imageBaseUrl =
      "http://10.0.2.2/car_rental_backend/images/customerImge/";

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await http.get(Uri.parse(apiUrl));

      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}");
      }

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        setState(() {
          customers = (data["customers"] as List).cast<Map<String, dynamic>>();
        });
      } else {
        setState(() {
          error = (data["message"] ?? "Unknown error").toString();
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() => loading = false);
    }
  }

  // =========================
  // Customer Card
  // =========================
  Widget _customerCard(Map<String, dynamic> c) {
    final name = (c["full_name"] ?? "").toString();
    final email = (c["email"] ?? "").toString();
    final phone = (c["phone"] ?? "").toString();
    final imgName = (c["imageName"] ?? "").toString().trim();

    final imgUrl = imgName.isEmpty ? null : "$imageBaseUrl$imgName";

    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 90,
                height: 90,
                color: Colors.grey.shade200,
                child: imgUrl == null
                    ? const Icon(Icons.person, size: 40)
                    : Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, size: 40),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          email,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          phone,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Build
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E2E2),
      drawer: EmployeeDrawer(
        employeeName: widget.employeeName,
        employeeImageUrl: widget.employeeImageUrl,
        current: "customers",
      ),
      appBar: AppBar(
        title: const Text("Customers"),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchCustomers,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text("Error: $error"))
              : ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, i) => _customerCard(customers[i]),
                ),
    );
  }
}
