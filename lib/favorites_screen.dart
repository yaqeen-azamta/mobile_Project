import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'car_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool loading = true;
  List favorites = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final cid = prefs.getInt("customer_id");
    if (cid == null) return;

    final url = Uri.parse(
      "http://10.0.2.2/car_rental_backend/api/get_favorites.php?customer_id=$cid",
    );
    final res = await http.get(url);
    final json = jsonDecode(res.body);

    setState(() {
      favorites = (json["success"] == true) ? json["favorites"] ?? [] : [];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorites")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? const Center(child: Text("No favorites yet"))
              : ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, i) {
                    final c = favorites[i];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.favorite, color: Colors.red),
                        title: Text(
                          "${c["brand"]} ${c["model"]} (${c["year"]})",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("${c["daily_price"]} ₪ / day"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CarDetailsScreen(car: c),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
