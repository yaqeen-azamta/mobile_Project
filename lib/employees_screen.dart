import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'employee.dart';
import 'manager_drawer.dart';
import 'employee_add_screen.dart';

const kBurgundy = Color(0xFF800020);

class EmployeesScreen extends StatefulWidget {
  EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late Future<List<Employee>> _future;
  final _search = TextEditingController();
  bool _hasChanges = false;

  static const String _employeesUrl =
      'http://10.0.2.2/car_rental_backend/api/employees_list.php';

  @override
  void initState() {
    super.initState();
    _future = _fetchEmployees();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Employee>> _fetchEmployees({String q = ""}) async {
    final uri = Uri.parse(_employeesUrl).replace(
      queryParameters: q.trim().isEmpty ? null : {"q": q.trim()},
    );

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = json.decode(res.body);
    if (decoded is! List) {
      throw Exception("Invalid employees response");
    }

    return decoded.map<Employee>((e) => Employee.fromJson(e)).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _fetchEmployees(q: _search.text);
    });
    await _future;
  }

  Future<void> _openAdd() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EmployeeAddScreen()),
    );

    if (changed == true) {
      _hasChanges = true;
      await _refresh();
    }
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: _search,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _refresh(),
        decoration: InputDecoration(
          hintText: "Search by name / email / national ID",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _search.clear();
              _refresh();
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _employeeCard(Employee e) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: kBurgundy.withOpacity(0.12),
              child: const Icon(Icons.badge, color: kBurgundy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Email: ${e.email}",
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "National ID: ${e.nationalId}",
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if ((e.phone ?? "").trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Phone: ${e.phone}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Employees"),
          backgroundColor: kBurgundy,
          foregroundColor: Colors.white,
        ),
        drawer: const ManagerDrawer(current: "employees"),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: kBurgundy,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add),
          label: const Text("Add Employee"),
          onPressed: _openAdd,
        ),
        body: Column(
          children: [
            _searchBar(),
            Expanded(
              child: FutureBuilder<List<Employee>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          snapshot.error.toString(),
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final list = snapshot.data ?? [];

                  if (list.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        children: const [
                          SizedBox(height: 220),
                          Center(
                            child: Text("No employees found"),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _employeeCard(list[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
