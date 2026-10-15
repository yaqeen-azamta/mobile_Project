import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'car_details_screen.dart';
import 'contact_us_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'customer_profile_screen.dart';
import 'favorites_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class CarListScreen extends StatefulWidget {
  const CarListScreen({super.key});

  @override
  State<CarListScreen> createState() => _CarListScreenState();
}

class _CarListScreenState extends State<CarListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool isLoggedIn = false;

  String? selectedType;

  String? selectedBrand;

  String? selectedColor;
  RangeValues priceRange = const RangeValues(0, 10000000);

  List<Map<String, dynamic>> cars = [];
  bool loading = true;
  String? apiError;

  static const String apiUrl =
      'http://10.0.2.2/car_rental_backend/api/cars.php';
  static const String imageBaseUrl =
      'http://10.0.2.2/car_rental_backend/images/carImage/';

  Future<void> fetchCars() async {
    setState(() {
      loading = true;
      apiError = null;
    });

    try {
      final url = Uri.parse(apiUrl);
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (jsonMap['success'] == true) {
        final list = (jsonMap['cars'] as List).cast<Map<String, dynamic>>();
        setState(() => cars = list);
      } else {
        setState(() {
          apiError = (jsonMap['message'] ?? 'Unknown error').toString();
        });
      }
    } catch (e) {
      setState(() => apiError = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.containsKey("customer_id");
    });
  }

  @override
  void initState() {
    super.initState();
    fetchCars();
    _checkLoginStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkLoginStatus();
  }

  List<String> get brands {
    final set = <String>{};
    for (final c in cars) {
      final b = (c["brand"] ?? "").toString().trim();
      if (b.isNotEmpty) set.add(b);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  String? _brandLogo(String brand) {
    final b = brand.toLowerCase().trim();

    if (b == "hyundai") return "assets/brands/hyundai.jpg";
    if (b == "toyota") return "assets/brands/toyota.jpg";
    if (b == "kia") return "assets/brands/kia.jpg";
    if (b == "bmw") return "assets/brands/bmw.jpg";
    if (b == "mercedes") return "assets/brands/mercedes.jpg";

    return null;
  }

  // -----------------------
  // Filtering Logic
  // -----------------------
  List<Map<String, dynamic>> get filteredCars {
    final q = _searchCtrl.text.trim().toLowerCase();

    return cars.where((c) {
      final brand = (c["brand"] ?? "").toString().toLowerCase();
      final model = (c["model"] ?? "").toString().toLowerCase();
      final combined = "$brand $model";
      final nameMatch = combined.contains(q);

      final typeMatch =
          selectedType == null || (c["type"] ?? "").toString() == selectedType;

      final brandMatch = selectedBrand == null ||
          (c["brand"] ?? "").toString() == selectedBrand;

      final colorMatch = selectedColor == null ||
          (c["color"] ?? "").toString() == selectedColor;

      final price = double.tryParse(c["daily_price"]?.toString() ?? "") ?? 0.0;
      final priceMatch = price >= priceRange.start && price <= priceRange.end;

      return nameMatch && typeMatch && brandMatch && colorMatch && priceMatch;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // =======================
  // 1) Search Row
  // =======================
  Widget _searchRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search cars...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.tune),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  // =======================
  // ✅ Brands Row
  // =======================
  Widget _brandRow() {
    if (loading || brands.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _brandItem(
            label: "All",
            selected: selectedBrand == null,
            onTap: () => setState(() => selectedBrand = null),
            fallbackIcon: Icons.directions_car,
          ),
          const SizedBox(width: 12),
          ...brands.map((b) {
            final selected = selectedBrand == b;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _brandItem(
                label: b,
                selected: selected,
                onTap: () =>
                    setState(() => selectedBrand = selected ? null : b),
                logoPath: _brandLogo(b),
                fallbackIcon: Icons.directions_car,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _brandItem({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? logoPath,
    IconData? fallbackIcon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: selected ? Colors.black : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: logoPath != null
                  ? ClipOval(
                      child: Image.asset(
                        logoPath,
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                      ),
                    )
                  : Icon(
                      fallbackIcon ?? Icons.directions_car,
                      color: selected ? Colors.white : Colors.black,
                    ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.black : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =======================
  // 2) Car Card
  // =======================
  Widget _carCard(Map<String, dynamic> car) {
    final name = "${car["brand"]} ${car["model"]}";
    final type = (car["type"] ?? "").toString();
    final color = (car["color"] ?? "").toString();
    final daily = double.tryParse((car["daily_price"] ?? "").toString()) ?? 0.0;
    final plate = (car["plate_number"] ?? "").toString();
    final status = (car["status"] ?? "").toString();

    final imgName = (car["imageName"] ?? "").toString().trim();
    final imgUrl = imgName.isEmpty ? null : "$imageBaseUrl$imgName";

    return SizedBox(
      width: 320,
      child: Card(
        color: Colors.white,
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imgUrl == null
                      ? const Center(
                          child: Icon(Icons.directions_car, size: 40),
                        )
                      : Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.directions_car, size: 40),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$type • $color • $status\nPlate: $plate",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Daily",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "${daily.toStringAsFixed(2)} ILS",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF800020),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CarDetailsScreen(car: car),
                      ),
                    );
                  },
                  child: const Text(
                    "Details",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =======================
  // 3) Filter BottomSheet
  // =======================
  void _openFilterSheet() {
    String? tempType = selectedType;
    String? tempColor = selectedColor;
    RangeValues tempRange = priceRange;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Filter",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text("Type"),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: tempType,
                      items: const [
                        DropdownMenuItem(value: "SUV", child: Text("SUV")),
                        DropdownMenuItem(value: "Sedan", child: Text("Sedan")),
                        DropdownMenuItem(
                          value: "Hatchback",
                          child: Text("Hatchback"),
                        ),
                      ],
                      onChanged: (v) => setSheetState(() => tempType = v),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("Color"),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ["Black", "White", "Red", "Blue", "Gray"]
                          .map((color) {
                        final selected = tempColor == color;
                        return ChoiceChip(
                          label: Text(color),
                          selected: selected,
                          onSelected: (_) => setSheetState(() {
                            tempColor = selected ? null : color;
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Price per day: ${tempRange.start.toInt()} - ${tempRange.end.toInt()}",
                      style: const TextStyle(
                        color: Color(0xFF800020),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF800020),
                        inactiveTrackColor:
                            const Color(0xFF800020).withOpacity(0.25),
                        thumbColor: const Color(0xFF800020),
                        overlayColor: const Color(0xFF800020).withOpacity(0.15),
                      ),
                      child: RangeSlider(
                        values: tempRange,
                        min: 0,
                        max: 10000000,
                        divisions: 100,
                        onChanged: (v) => setSheetState(() => tempRange = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                tempType = null;
                                tempColor = null;
                                tempRange = const RangeValues(0, 10000000);
                              });
                            },
                            child: const Text("Reset"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedType = tempType;
                                selectedColor = tempColor;
                                priceRange = tempRange;
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text("Apply"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =======================
  // Drawer
  // =======================
  Drawer _appDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.6,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(22)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Menu",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),

            // ===============================
            // Home
            // ===============================
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),

            if (!isLoggedIn)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text("Login"),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  if (result == true && mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const CarListScreen()),
                    );
                  }
                },
              ),

            if (!isLoggedIn)
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text("Sign Up"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
              ),

            // ===============================
            // Favorites ⭐ (NEW)
            // ===============================
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text("Favorites"),
              onTap: () async {
                Navigator.pop(context);

                final prefs = await SharedPreferences.getInstance();
                final customerId = prefs.getInt("customer_id");

                Future.microtask(() async {
                  if (customerId == null) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(fromRent: false),
                      ),
                    );

                    if (result == true) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FavoritesScreen(),
                        ),
                      );
                    }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    );
                  }
                });
              },
            ),

            // ===============================
            // Contact Us
            // ===============================
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text("Contact Us"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                );
              },
            ),

            // ===============================
            // Profile
            // ===============================
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () async {
                Navigator.pop(context);

                final prefs = await SharedPreferences.getInstance();
                final customerId = prefs.getInt("customer_id");

                Future.microtask(() async {
                  if (customerId == null) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(fromRent: false),
                      ),
                    );

                    if (result == true) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerProfileScreen(),
                        ),
                      );
                    }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerProfileScreen(),
                      ),
                    );
                  }
                });
              },
            ),
            if (isLoggedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Sign Out"),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const CarListScreen()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // =======================
  // Build
  // =======================
  @override
  Widget build(BuildContext context) {
    final list = filteredCars;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text("Car Rentals"),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                "assets/brands/LMYI.jpg",
                height: 150,
                width: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
      drawer: _appDrawer(),
      body: Column(
        children: [
          _searchRow(),
          const SizedBox(height: 8),
          _brandRow(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : (apiError != null)
                    ? Center(child: Text("Error: $apiError"))
                    : ListView(
                        children: list.isEmpty
                            ? const [
                                Padding(
                                  padding: EdgeInsets.only(top: 40),
                                  child: Center(
                                    child: Text("No cars match your filters."),
                                  ),
                                ),
                              ]
                            : list.map(_carCard).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}
