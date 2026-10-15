import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'cars.dart';
import 'manager_drawer.dart';
import 'add_edit_car_screen.dart';

const kBurgundy = Color(0xFF800020);

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  late Future<List<Car>> _carsFuture;
  bool _hasChanges = false;

  static const String _carsUrl =
      'http://10.0.2.2/car_rental_backend/api/cars_list.php';
  static const String _updateStatusUrl =
      'http://10.0.2.2/car_rental_backend/api/car_update_status.php';

  @override
  void initState() {
    super.initState();
    _carsFuture = _fetchCars();
  }

  Future<List<Car>> _fetchCars() async {
    final res = await http.get(Uri.parse(_carsUrl));

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = json.decode(res.body);

    if (decoded is! Map || decoded["data"] is! List) {
      throw Exception("Invalid cars response");
    }

    final List list = decoded["data"];
    return list.map<Car>((e) => Car.fromJson(e)).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _carsFuture = _fetchCars();
    });
    await _carsFuture;
  }

  void _markChanged() {
    if (_hasChanges) return;
    _hasChanges = true;
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case "AVAILABLE":
        return Colors.green;
      case "RENTED":
        return Colors.orange;
      case "MAINTENANCE":
        return Colors.blueGrey;
      case "DISABLED":
        return Colors.red;
      default:
        return Colors.black54;
    }
  }

  Widget _statusChip(String status) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  static Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Future<void> _openAddCar() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditCarScreen()),
    );

    if (changed == true) {
      _markChanged();
      await _refresh();
    }
  }

  Future<void> _openEditCar(Car car) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditCarScreen(car: car)),
    );

    if (changed == true) {
      _markChanged();
      await _refresh();
    }
  }

  Future<void> _changeStatus(Car car) async {
    const statuses = ["AVAILABLE", "RENTED", "MAINTENANCE", "DISABLED"];
    String selected = car.status.toUpperCase();

    final picked = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change status"),
        content: DropdownButtonFormField<String>(
          value: selected,
          items: statuses
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => selected = v ?? selected,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kBurgundy,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, selected),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (picked == null || picked == car.status.toUpperCase()) return;

    final res = await http.post(
      Uri.parse(_updateStatusUrl),
      body: {
        "car_id": car.carId.toString(),
        "status": picked,
      },
    );

    final decoded = json.decode(res.body);
    if (decoded is! Map || decoded["success"] != true) {
      throw Exception(decoded["message"] ?? "Update failed");
    }

    if (!mounted) return;
    _markChanged();
    await _refresh();
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
          title: const Text("Cars Management"),
          backgroundColor: kBurgundy,
          foregroundColor: Colors.white,
        ),
        drawer: const ManagerDrawer(current: "cars"),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: kBurgundy,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text("Add Car"),
          onPressed: _openAddCar,
        ),
        body: FutureBuilder<List<Car>>(
          future: _carsFuture,
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

            final cars = snapshot.data ?? [];
            if (cars.isEmpty) {
              return const Center(child: Text("No cars found"));
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: cars.length,
                itemBuilder: (context, i) {
                  final c = cars[i];
                  return ListTile(
                    title: Text("${c.brand} ${c.model}"),
                    subtitle: Text("Plate: ${c.plateNumber}"),
                    trailing: _statusChip(c.status),
                    onTap: () => _openEditCar(c),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
