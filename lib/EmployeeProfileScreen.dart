import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'employee_dashboard_screen.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  bool loading = true;

  String fullName = "";
  String email = "";
  String phone = "";
  String nationalId = "";
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final employeeId = prefs.getInt("employee_id");

    if (employeeId == null) {
      setState(() => loading = false);
      return;
    }

    final url = Uri.parse(
      "http://10.0.2.2/car_rental_backend/api/get_employee_profile.php?employee_id=$employeeId",
    );

    final res = await http.get(url);
    final json = jsonDecode(res.body);

    if (json["success"] == true) {
      final e = json["employee"];
      fullName = e["full_name"] ?? "";
      email = e["email"] ?? "";
      phone = e["phone"] ?? "";
      nationalId = e["national_id"] ?? "";
      imageUrl = e["image_url"];
    }

    setState(() => loading = false);
  }

  void _goBackToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const EmployeeDashboardScreen(
          employeeName: '',
          employeeImageUrl: '',
        ), // ⭐
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToDashboard,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.blueGrey,
                  backgroundImage:
                      imageUrl != null ? NetworkImage(imageUrl!) : null,
                  child: imageUrl == null
                      ? const Icon(Icons.person, size: 45, color: Colors.white)
                      : null,
                ),

                const SizedBox(height: 12),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(email, style: const TextStyle(color: Colors.grey)),
                Text(phone),
                const SizedBox(height: 8),
                Text("National ID: $nationalId"),
                const SizedBox(height: 20),

                // 🔙 زر رجوع صريح
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _goBackToDashboard,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Back to Dashboard"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
