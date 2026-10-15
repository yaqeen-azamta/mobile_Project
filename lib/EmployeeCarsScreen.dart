import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'employee_car_details_screen.dart';
import 'employee_drawer.dart';

class EmployeeCarsScreen extends StatefulWidget {
  final String employeeName;
  final String employeeImageUrl;

  const EmployeeCarsScreen({
    super.key,
    required this.employeeName,
    required this.employeeImageUrl,
  });

  @override
  State<EmployeeCarsScreen> createState() => _EmployeeCarsScreenState();
}

class _EmployeeCarsScreenState extends State<EmployeeCarsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String? selectedType;
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

  @override
  void initState() {
    super.initState();
    fetchCars();
  }

  List<Map<String, dynamic>> get filteredCars {
    final q = _searchCtrl.text.trim().toLowerCase();

    return cars.where((c) {
      final brand = (c["brand"] ?? "").toString().toLowerCase();
      final model = (c["model"] ?? "").toString().toLowerCase();
      final combined = "$brand $model";

      final nameMatch = combined.contains(q);

      final typeMatch =
          selectedType == null || c["type"].toString() == selectedType;
      final colorMatch =
          selectedColor == null || c["color"].toString() == selectedColor;

      final price = double.tryParse(c["daily_price"]?.toString() ?? "") ?? 0.0;
      final priceMatch = price >= priceRange.start && price <= priceRange.end;

      return nameMatch && typeMatch && colorMatch && priceMatch;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // =======================
  // Search Row
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
  // Car Card
  // =======================
  Widget _carCard(Map<String, dynamic> car) {
    final name = "${car["brand"]} ${car["model"]}";
    final type = car["type"].toString();
    final color = car["color"].toString();

    final daily = double.tryParse(car["daily_price"].toString()) ?? 0.0;
    final plate = (car["plate_number"] ?? "").toString();
    final status = (car["status"] ?? "").toString();

    final imgName = (car["imageName"] ?? "").toString().trim();
    final imgUrl = imgName.isEmpty ? null : "$imageBaseUrl$imgName";

    return SizedBox(
      width: 320,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black12,
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
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "${daily.toStringAsFixed(2)} ILS",
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                        builder: (_) => CarDetailsScreenEmployee(car: car),
                      ),
                    );
                  },
                  child: const Text("Details"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =======================
  // Filter BottomSheet
  // =======================
  void _openFilterSheet() {
    String? tempType = selectedType;
    String? tempColor = selectedColor;
    RangeValues tempRange = priceRange;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filter",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    children: ["Black", "White", "Red", "Blue", "Gray"].map((
                      c,
                    ) {
                      final selected = tempColor == c;
                      return ChoiceChip(
                        label: Text(c),
                        selected: selected,
                        onSelected: (_) => setSheetState(() {
                          tempColor = selected ? null : c;
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
                  RangeSlider(
                    values: tempRange,
                    min: 0,
                    max: 10000000,
                    divisions: 100,
                    onChanged: (v) => setSheetState(() => tempRange = v),
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
            );
          },
        );
      },
    );
  }

  // =======================
  // Build
  // =======================
  @override
  Widget build(BuildContext context) {
    final list = filteredCars;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      drawer: EmployeeDrawer(
        employeeName: widget.employeeName,
        employeeImageUrl: widget.employeeImageUrl,
        current: "cars",
      ),
      appBar: AppBar(
        title: const Text("Cars"),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchCars),
        ],
      ),
      body: Column(
        children: [
          _searchRow(),
          const SizedBox(height: 8),
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
