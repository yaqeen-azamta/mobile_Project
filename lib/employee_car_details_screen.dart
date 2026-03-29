import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CarDetailsScreenEmployee extends StatefulWidget {
  final Map<String, dynamic> car;

  const CarDetailsScreenEmployee({super.key, required this.car});

  static const Color burgundy = Color(0xFF800020);
  static const Color darkGrey = Color(0xFF2B2B2B);

  static const String imageBaseUrl =
      'http://10.0.2.2/car_rental_backend/images/carImage/';
  static const String imagesApi =
      'http://10.0.2.2/car_rental_backend/api/car_images.php';

  @override
  State<CarDetailsScreenEmployee> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreenEmployee> {
  late Future<List<String>> _imagesFuture;
  int _currentImageIndex = 0;

  int _carIdFromMap(Map<String, dynamic> car) {
    final raw = car["car_id"] ?? car["id"] ?? "";
    return int.tryParse(raw.toString()) ?? 0;
  }

  Future<List<String>> _fetchImages(int carId) async {
    if (carId <= 0) return [];

    final url =
        Uri.parse('${CarDetailsScreenEmployee.imagesApi}?car_id=$carId');
    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
    if (jsonMap['success'] == true) {
      final imgs =
          (jsonMap['images'] as List).map((e) => e.toString()).toList();
      return imgs;
    } else {
      throw Exception((jsonMap['message'] ?? 'Unknown error').toString());
    }
  }

  // =====================

  Future<Map<String, dynamic>> _fetchRating(int carId) async {
    final url = Uri.parse(
      "http://10.0.2.2/car_rental_backend/api/get_car_rating.php?car_id=$carId",
    );

    final res = await http.get(url);
    final json = jsonDecode(res.body);

    if (json["success"] == true) {
      return {
        "avg": double.tryParse(json["avg_rating"].toString()) ?? 0.0,
        "count": int.tryParse(json["reviews_count"].toString()) ?? 0,
      };
    }

    return {"avg": 0.0, "count": 0};
  }

  late Future<Map<String, dynamic>> _ratingFuture;

  @override
  void initState() {
    super.initState();
    final carId = _carIdFromMap(widget.car);
    _imagesFuture = _fetchImages(carId);
    _ratingFuture = _fetchRating(carId);
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    final name = "${car["brand"] ?? ""} ${car["model"] ?? ""}".trim();
    final type = (car["type"] ?? "N/A").toString();
    final color = (car["color"] ?? "N/A").toString();

    final daily =
        double.tryParse((car["daily_price"] ?? "0").toString()) ?? 0.0;

    final plate = (car["plate_number"] ?? "N/A").toString();
    final status = (car["status"] ?? "N/A").toString();

    final year = int.tryParse((car["year"] ?? "").toString());
    final seats = int.tryParse((car["seats"] ?? "").toString());

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: const Text("Car Details"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =====================
            SizedBox(
              height: 260,
              child: FutureBuilder<List<String>>(
                future: _imagesFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snap.hasError) {
                    return Container(
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.black12,
                      ),
                      child: const Center(child: Text("Failed to load images")),
                    );
                  }

                  final imgs = snap.data ?? [];
                  if (imgs.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.black12,
                      ),
                      child: const Center(
                        child: Icon(Icons.directions_car, size: 60),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      SizedBox(
                        height: 230,
                        child: PageView.builder(
                          itemCount: imgs.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, i) {
                            final url =
                                "${CarDetailsScreenEmployee.imageBaseUrl}${imgs[i]}";
                            return Container(
                              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.black12,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image, size: 50),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(imgs.length, (index) {
                          final isActive = index == _currentImageIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 10 : 6,
                            height: isActive ? 10 : 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? CarDetailsScreenEmployee.burgundy
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // =====================
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name.isEmpty ? "Unknown Car" : name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: CarDetailsScreenEmployee.darkGrey,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${daily.toStringAsFixed(0)} ILS",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: CarDetailsScreenEmployee.burgundy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "/ day",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$type • $color • $status",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _InfoChip(label: "Plate: $plate"),
                      if (year != null) _InfoChip(label: "Year: $year"),
                      if (seats != null) _InfoChip(label: "Seats: $seats"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: CarDetailsScreenEmployee.burgundy,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "4.6",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 6),
                      Text(
                        "(128 reviews)",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // =====================
            _sectionTitle("Specifications"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  const _SpecChip(icon: Icons.settings, label: "Automatic"),
                  _SpecChip(
                    icon: Icons.event_seat,
                    label: seats != null ? "$seats Seats" : "Seats",
                  ),
                  const _SpecChip(
                    icon: Icons.local_gas_station,
                    label: "Petrol",
                  ),
                  const _SpecChip(icon: Icons.ac_unit, label: "A/C"),
                  const _SpecChip(icon: Icons.luggage, label: "2 Bags"),
                  const _SpecChip(icon: Icons.speed, label: "Cruise"),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // =====================
            _sectionTitle("Description"),
            _sectionCard(
              child: const Text(
                "A comfortable and reliable car for city rides and long trips. "
                "Smooth driving experience, modern interior, and great fuel efficiency.",
                style: TextStyle(color: Colors.black87, height: 1.4),
              ),
            ),

            _sectionTitle("Rental Terms"),
            _sectionCard(
              child: const Column(
                children: [
                  _TermRow(title: "Minimum age", value: "21+"),
                  SizedBox(height: 8),
                  _TermRow(title: "Deposit", value: "500 ILS"),
                  SizedBox(height: 8),
                  _TermRow(title: "Insurance", value: "Included"),
                ],
              ),
            ),

            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  // =====================
  // Helpers
  // =====================
  static Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: CarDetailsScreenEmployee.darkGrey,
        ),
      ),
    );
  }

  static Widget _sectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: CarDetailsScreenEmployee.burgundy),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  final String title;
  final String value;

  const _TermRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}
