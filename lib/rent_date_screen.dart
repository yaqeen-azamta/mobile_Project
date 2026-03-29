import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'map_picker_screen.dart';

class RentDateScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  final int customerId;

  const RentDateScreen({
    super.key,
    required this.car,
    required this.customerId,
  });

  @override
  State<RentDateScreen> createState() => _RentDateScreenState();
}

class _RentDateScreenState extends State<RentDateScreen> {
  DateTime? startDate;
  DateTime? endDate;

  String? pickupName;
  double? pickupLat;
  double? pickupLng;

  String? dropoffName;
  double? dropoffLat;
  double? dropoffLng;

  String paymentMethod = "CASH";

  bool loading = false;
  bool pickupFromCompany = false;
  bool dropoffFromCompany = false;

  static const String companyName = "Car Rental Company";
  static const double companyLat = 31.9038;
  static const double companyLng = 35.2034;

  List<DateTime> blockedDates = [];

  double walletBalance = 0;
  bool walletChecked = false;

  static const String apiBase = "http://10.0.2.2/car_rental_backend/api";

  @override
  void initState() {
    super.initState();
    _loadBlockedDates();
  }

  Future<void> _loadBlockedDates() async {
    try {
      final res = await http.get(
        Uri.parse(
          "$apiBase/get_car_booked_dates.php?car_id=${widget.car['car_id']}",
        ),
      );

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        List<DateTime> temp = [];

        for (var r in data["booked_dates"]) {
          DateTime s = DateTime.parse(r["start_date"]);
          DateTime e = DateTime.parse(r["end_date"]);

          for (int i = 0; i <= e.difference(s).inDays; i++) {
            temp.add(s.add(Duration(days: i)));
          }
        }

        setState(() => blockedDates = temp);
      }
    } catch (e) {
      debugPrint(" Failed to load blocked dates: $e");
    }
  }

  bool _isBlocked(DateTime day) {
    return blockedDates.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day,
    );
  }

  DateTime _firstAvailableDate() {
    DateTime day = DateTime.now();
    for (int i = 0; i < 365; i++) {
      if (!_isBlocked(day)) return day;
      day = day.add(const Duration(days: 1));
    }
    return DateTime.now();
  }

  Future<void> _pickDate(bool isStart) async {
    final DateTime initial = startDate != null && !_isBlocked(startDate!)
        ? startDate!
        : _firstAvailableDate();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (day) => !_isBlocked(day),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (endDate != null && endDate!.isBefore(startDate!)) {
            endDate = null;
          }
        } else {
          endDate = picked;
        }
      });
    }
  }

  int get rentalDays {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays + 1;
  }

  double get pricePerDay => double.parse(widget.car['daily_price'].toString());

  double get totalPrice => rentalDays * pricePerDay;

  Future<void> _loadWalletBalance() async {
    try {
      final res = await http.get(
        Uri.parse(
          "$apiBase/get_wallet_balance.php?customer_id=${widget.customerId}",
        ),
      );

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        setState(() {
          walletBalance = (data["balance"] as num).toDouble();
          walletChecked = true;
        });
      }
    } catch (e) {
      debugPrint("Wallet error: $e");
    }
  }

  Future<void> createRental() async {
    if (startDate == null || endDate == null) {
      _snack("Please select dates");
      return;
    }

    if (pickupLat == null || dropoffLat == null) {
      _snack("Please select pickup & drop-off locations");
      return;
    }

    if (paymentMethod == "WALLET") {
      if (!walletChecked) {
        _snack("Checking wallet balance...");
        return;
      }
      if (walletBalance < totalPrice) {
        _snack("Insufficient wallet balance");
        return;
      }
    }

    final payload = {
      "customer_id": widget.customerId,
      "car_id": widget.car['car_id'],
      "start_date": _formatDate(startDate),
      "end_date": _formatDate(endDate),
      "total_price": totalPrice,
      "payment_method": paymentMethod,
      "pickup_lat": pickupLat,
      "pickup_lng": pickupLng,
      "pickup_location_name": pickupName,
      "dropoff_lat": dropoffLat,
      "dropoff_lng": dropoffLng,
      "dropoff_location_name": dropoffName,
    };

    setState(() => loading = true);

    try {
      final res = await http.post(
        Uri.parse("$apiBase/create_rental.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      setState(() => loading = false);
      final data = jsonDecode(res.body);

      if (data["success"] == true && mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Request Submitted"),
            content: const Text("Your rental request is pending approval."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        _snack(data["message"] ?? "Failed");
      }
    } catch (e) {
      setState(() => loading = false);
      _snack("Server error");
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return "";
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rent Car")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _sectionCard(
              title: "Rental Dates",
              child: Column(
                children: [
                  _dateTile("Start Date", startDate, () => _pickDate(true)),
                  _dateTile("End Date", endDate, () => _pickDate(false)),
                  const SizedBox(height: 6),
                  Text(
                    "Gray dates are already booked",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            _sectionCard(
              title: "Payment",
              child: DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "CASH", child: Text("Cash")),
                  DropdownMenuItem(value: "WALLET", child: Text("Wallet")),
                ],
                onChanged: (v) {
                  setState(() {
                    paymentMethod = v!;
                    walletChecked = false;
                  });
                  if (v == "WALLET") _loadWalletBalance();
                },
              ),
            ),
            if (rentalDays > 0)
              _sectionCard(
                title: "Summary",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Days: $rentalDays"),
                    Text("Price per day: $pricePerDay ₪"),
                    const Divider(),
                    Text(
                      "Total: $totalPrice ₪",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (paymentMethod == "WALLET")
                      Text(
                        "Wallet balance: $walletBalance ₪",
                        style: TextStyle(
                          color: walletBalance >= totalPrice
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
            _sectionCard(
              title: "Pickup Location",
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text("Pickup from company"),
                    value: pickupFromCompany,
                    onChanged: (v) {
                      setState(() {
                        pickupFromCompany = v!;
                        if (v) {
                          pickupName = companyName;
                          pickupLat = companyLat;
                          pickupLng = companyLng;
                        } else {
                          pickupName = null;
                          pickupLat = null;
                          pickupLng = null;
                        }
                      });
                    },
                  ),
                  if (!pickupFromCompany)
                    _locationTile(
                      "Pickup Location",
                      pickupName,
                      (r) {
                        pickupName = r['name'];
                        pickupLat = r['lat'];
                        pickupLng = r['lng'];
                      },
                    ),
                  if (pickupFromCompany)
                    ListTile(
                      title: const Text("Pickup Location"),
                      subtitle: Text(companyName),
                      trailing: const Icon(Icons.business),
                    ),
                ],
              ),
            ),
            _sectionCard(
              title: "Drop-off Location",
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text("Drop-off at company"),
                    value: dropoffFromCompany,
                    onChanged: (v) {
                      setState(() {
                        dropoffFromCompany = v!;
                        if (v) {
                          dropoffName = companyName;
                          dropoffLat = companyLat;
                          dropoffLng = companyLng;
                        } else {
                          dropoffName = null;
                          dropoffLat = null;
                          dropoffLng = null;
                        }
                      });
                    },
                  ),
                  if (!dropoffFromCompany)
                    _locationTile(
                      "Drop-off Location",
                      dropoffName,
                      (r) {
                        dropoffName = r['name'];
                        dropoffLat = r['lat'];
                        dropoffLng = r['lng'];
                      },
                    ),
                  if (dropoffFromCompany)
                    ListTile(
                      title: const Text("Drop-off Location"),
                      subtitle: Text(companyName),
                      trailing: const Icon(Icons.business),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : createRental,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Rental Request"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _dateTile(String title, DateTime? date, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(date == null ? "Select date" : _formatDate(date)),
      trailing: const Icon(Icons.calendar_month),
      onTap: onTap,
    );
  }

  Widget _locationTile(
    String title,
    String? value,
    Function(Map) onSelected,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(value ?? "Select from map"),
      trailing: const Icon(Icons.map),
      onTap: () async {
        final r = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapPickerScreen()),
        );
        if (r != null) setState(() => onSelected(r));
      },
    );
  }
}
