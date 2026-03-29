import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'wallet_screen.dart';
import 'edit_profile_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool loading = true;

  String fullName = "";
  String email = "";
  String phone = "";
  double balance = 0.0;

  List rentals = [];
  List notifications = [];

  int loyaltyPoints = 0;
  String loyaltyLevel = "BRONZE";
  String nextLevel = "SILVER";
  int nextTarget = 500;
  double loyaltyProgress = 0.0;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt("customer_id");

    if (customerId == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      await Future.wait([
        _loadProfile(customerId),
        _loadRentals(customerId),
        _loadNotifications(customerId),
        _loadLoyalty(customerId),
      ]);
    } catch (_) {}

    if (mounted) setState(() => loading = false);
  }

  // ===============================
  // Profile
  // ===============================
  Future<void> _loadProfile(int id) async {
    final url = Uri.parse(
      "http://10.0.2.2/car_rental_backend/api/get_customer_profile.php?customer_id=$id",
    );

    final res = await http.get(url);
    final json = jsonDecode(res.body);

    if (json["success"] == true && json["customer"] != null) {
      final c = json["customer"];
      fullName = c["full_name"] ?? "";
      email = c["email"] ?? "";
      phone = c["phone"] ?? "";
      balance = double.tryParse(c["balance"]?.toString() ?? "0") ?? 0.0;
      imageUrl = c["imageName"] != null && c["imageName"] != ""
          ? "http://10.0.2.2/car_rental_backend/images/customerimage/${c["imageName"]}"
          : null;
    }
  }

  // ===============================
  // Rentals
  // ===============================
  Future<void> _loadRentals(int id) async {
    final url = Uri.parse(
      "http://10.0.2.2/car_rental_backend/api/get_customer_rentals.php?customer_id=$id",
    );

    final res = await http.get(url);
    final json = jsonDecode(res.body);

    rentals = (json["success"] == true) ? json["rentals"] ?? [] : [];
  }

  // ===============================
  // Notifications
  // ===============================
  Future<void> _loadNotifications(int id) async {
    final url = Uri.parse(
      "http://10.0.2.2/car_rental_backend/api/get_customer_notifications.php?customer_id=$id",
    );

    final res = await http.get(url);
    final json = jsonDecode(res.body);

    notifications =
        (json["success"] == true) ? json["notifications"] ?? [] : [];
  }

  Future<void> _loadLoyalty(int id) async {
    final url = Uri.parse(
      "http://10.0.2.2/car_rental_backend/api/get_customer_loyalty.php?customer_id=$id",
    );

    final res = await http.get(url);
    final json = jsonDecode(res.body);

    if (json["success"] == true && json["loyalty"] != null) {
      final l = json["loyalty"];
      loyaltyPoints = int.tryParse(l["points"].toString()) ?? 0;
      loyaltyLevel = l["level"]?.toString() ?? "BRONZE";
      nextLevel = l["next_level"]?.toString() ?? "SILVER";
      nextTarget = int.tryParse(l["next_target"].toString()) ?? 500;
      loyaltyProgress = double.tryParse(l["progress"].toString()) ?? 0.0;
    }
  }

  // ===============================
  // 🔔 Open Notifications Sheet
  // ===============================
  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7, // يفتح على 70% من الشاشة
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ───── Header ─────
                  const Text(
                    "Notifications",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // ───── List ─────
                  Expanded(
                    child: notifications.isEmpty
                        ? const Center(
                            child: Text("No notifications yet"),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: notifications.length,
                            itemBuilder: (context, i) {
                              final n = notifications[i];

                              IconData icon = Icons.info;
                              Color color = Colors.grey;

                              if (n["type"] == "payment") {
                                icon = Icons.payment;
                                color = Colors.green;
                              } else if (n["type"] == "booking") {
                                icon = Icons.directions_car;
                                switch (n["status"]) {
                                  case "ACTIVE":
                                    color = Colors.green;
                                    break;
                                  case "PENDING":
                                    color = Colors.orange;
                                    break;
                                  case "COMPLETED":
                                    color = Colors.blue;
                                    break;
                                  case "CANCELLED":
                                    color = Colors.red;
                                    break;
                                  default:
                                    color = Colors.grey;
                                }
                              } else if (n["type"] == "system") {
                                icon = Icons.stars;
                                color = Colors.purple;
                              }

                              return ListTile(
                                leading: Icon(icon, color: color),
                                title: Text(
                                  n["title"],
                                  style: TextStyle(
                                    fontWeight: n["is_read"] == 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(n["message"]),
                                trailing: Text(
                                  n["created_at"].toString().substring(0, 10),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _openNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    name: fullName,
                    email: email,
                    phone: phone,
                  ),
                ),
              );

              if (updated == true) _loadAll();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===============================
            // Profile Header
            // ===============================
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: const Color(0xFF800020),
                      backgroundImage:
                          imageUrl != null ? NetworkImage(imageUrl!) : null,
                      child: imageUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 45,
                              color: Colors.white,
                            )
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
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(color: Colors.grey)),
                    Text(phone),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ===============================
            //Loyalty Card
            // ===============================
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(
                          "Loyalty: $loyaltyLevel",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text("$loyaltyPoints pts"),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: loyaltyProgress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    const SizedBox(height: 8),
                    Text("Next: $nextLevel at $nextTarget pts"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ===============================
            // Wallet Section
            // ===============================
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text("My Wallet"),
                subtitle: Text(
                  "Balance: ${balance.toStringAsFixed(2)} ₪",
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WalletScreen(),
                    ),
                  );

                  if (updated == true) _loadAll();
                },
              ),
            ),

            const SizedBox(height: 24),

            // ===============================
            // Rental History
            // ===============================
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Rental History",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            rentals.isEmpty
                ? const Text("No rentals yet")
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rentals.length,
                    itemBuilder: (context, i) {
                      final r = rentals[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.directions_car),
                          title: Text(
                            "${r["brand"]} ${r["model"]} (${r["year"]})",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "From ${r["start_date"]} to ${r["end_date"]}"),
                                Text("Payment: ${r["payment_method"]}"),
                                Text(
                                  "Status: ${r["rental_status"]}",
                                  style: TextStyle(
                                    color: r["rental_status"] == "ACTIVE"
                                        ? Colors.green
                                        : r["rental_status"] == "PENDING"
                                            ? Colors.orange
                                            : r["rental_status"] == "COMPLETED"
                                                ? Colors.blue
                                                : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Text(
                            "${r["total_price"]} ₪",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
