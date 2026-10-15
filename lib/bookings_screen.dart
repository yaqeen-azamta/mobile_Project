import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'booking.dart';
import 'cars.dart';
import 'manager_drawer.dart';

const kBurgundy = Color(0xFF800020);

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    "PENDING",
    "PENDING",
    "ACTIVE",
    "COMPLETED",
    "CANCELLED"
  ];

  static const _tabTitles = [
    "Pending",
    "Approved",
    "Active",
    "Completed",
    "Cancelled"
  ];

  late Future<List<Booking>> _future;
  int _tabIndex = 0;

  List<Car> _carsCache = [];
  bool _carsLoaded = false;

  static const String _base = 'http://10.0.2.2/car_rental_backend/api';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _tabIndex = _tabController.index;
        _future = _fetchBookings(_tabs[_tabIndex]);
      });
    });
    _future = _fetchBookings(_tabs[_tabIndex]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Booking>> _fetchBookings(String status) async {
    final uri = Uri.parse("$_base/bookings_list.php")
        .replace(queryParameters: {"status": status});

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = json.decode(res.body);
    if (decoded is! List) {
      throw Exception("Invalid bookings response");
    }

    return decoded.map<Booking>((e) => Booking.fromJson(e)).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _fetchBookings(_tabs[_tabIndex]);
    });
    await _future;
  }

  Future<void> _ensureCarsLoaded() async {
    if (_carsLoaded) return;

    final res = await http.get(Uri.parse("$_base/cars_list.php"));
    if (res.statusCode != 200) {
      throw Exception("Failed to load cars");
    }

    final decoded = json.decode(res.body);
    _carsCache = (decoded as List).map<Car>((e) => Car.fromJson(e)).toList();
    _carsLoaded = true;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _updateStatus(int id, String status) async {
    final res = await http.post(
      Uri.parse("$_base/booking_update_status.php"),
      body: {"booking_id": id.toString(), "status": status},
    );

    if (res.statusCode != 200) {
      throw Exception("Update failed");
    }
  }

  Future<void> _assignCar(int bookingId, int carId) async {
    final res = await http.post(
      Uri.parse("$_base/booking_assign_car.php"),
      body: {"booking_id": bookingId.toString(), "car_id": carId.toString()},
    );

    if (res.statusCode != 200) {
      throw Exception("Assign failed");
    }
  }

  // ---------------- UI Helpers ----------------

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case "PENDING":
        return Colors.orange;
      case "APPROVED":
        return Colors.blue;
      case "ACTIVE":
        return Colors.green;
      case "COMPLETED":
        return Colors.grey;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.black54;
    }
  }

  Widget _statusPill(String status) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }

  Widget _priceBadge(double price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kBurgundy.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        "${price.toStringAsFixed(2)} ₪",
        style: const TextStyle(color: kBurgundy, fontWeight: FontWeight.w900),
      ),
    );
  }

  // ---------------- Actions ----------------

  Future<void> _approve(Booking b) async {
    await _updateStatus(b.bookingId, "APPROVED");
    _toast("Booking approved");
    _refresh();
  }

  Future<void> _reject(Booking b) async {
    await _updateStatus(b.bookingId, "CANCELLED");
    _toast("Booking rejected");
    _refresh();
  }

  Future<void> _markActive(Booking b) async {
    await _updateStatus(b.bookingId, "ACTIVE");
    _toast("Marked active");
    _refresh();
  }

  Future<void> _markCompleted(Booking b) async {
    await _updateStatus(b.bookingId, "COMPLETED");
    _toast("Marked completed");
    _refresh();
  }

  Future<void> _assign(Booking b) async {
    await _ensureCarsLoaded();

    final available = _carsCache.where((c) => c.status == "AVAILABLE").toList();

    if (available.isEmpty) {
      _toast("No available cars");
      return;
    }

    int selected = available.first.carId;

    final picked = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Assign car"),
        content: DropdownButtonFormField<int>(
          value: selected,
          items: available
              .map((c) => DropdownMenuItem(
                  value: c.carId, child: Text("${c.brand} ${c.model}")))
              .toList(),
          onChanged: (v) => selected = v ?? selected,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kBurgundy),
              onPressed: () => Navigator.pop(context, selected),
              child: const Text("Assign")),
        ],
      ),
    );

    if (picked == null) return;

    await _assignCar(b.bookingId, picked);
    _toast("Car assigned");
    _refresh();
  }

  // ---------------- Card ----------------

  Widget _bookingCard(Booking b) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(b.customerName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
                ),
                _statusPill(b.status),
              ],
            ),
            const SizedBox(height: 8),
            Text("Pickup: ${b.pickupDate} • Return: ${b.returnDate}",
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 10),
            Row(
              children: [
                _priceBadge(b.totalPrice),
                const Spacer(),
                Text("#${b.bookingId}",
                    style: const TextStyle(color: Colors.black45)),
              ],
            ),
            const SizedBox(height: 12),
            if (b.status == "PENDING")
              Wrap(spacing: 10, children: [
                _action("Approve", Icons.check, () => _approve(b)),
                _action("Reject", Icons.close, () => _reject(b), filled: false),
                _action("Assign", Icons.car_rental, () => _assign(b)),
              ]),
            if (b.status == "APPROVED")
              _action("Mark Active", Icons.play_arrow, () => _markActive(b)),
            if (b.status == "ACTIVE")
              _action("Complete", Icons.flag, () => _markCompleted(b)),
          ],
        ),
      ),
    );
  }

  Widget _action(String text, IconData icon, VoidCallback onTap,
      {bool filled = true}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: filled ? kBurgundy : Colors.white,
        foregroundColor: filled ? Colors.white : kBurgundy,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookings Management"),
        backgroundColor: kBurgundy,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: List.generate(_tabs.length, (i) => Tab(text: _tabTitles[i])),
        ),
      ),
      drawer: const ManagerDrawer(current: "bookings"),
      body: FutureBuilder<List<Booking>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text(snapshot.error.toString(),
                    style: const TextStyle(color: Colors.red)));
          }

          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text("No bookings found"));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _bookingCard(list[i]),
            ),
          );
        },
      ),
    );
  }
}
