import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  double lat = 31.9038;
  double lng = 35.2034;
  Future<void> _openGoogleMaps() async {
    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";

    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Maps")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Location"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              "Choose Location",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Google Maps will open in a separate app.\n"
              "Select the location manually, then return and confirm.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text("Open Google Maps"),
                onPressed: _openGoogleMaps,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text("Confirm Location"),
                onPressed: () {
                  Navigator.pop(context, {
                    "lat": lat,
                    "lng": lng,
                    "name":
                        "Lat ${lat.toStringAsFixed(5)}, Lng ${lng.toStringAsFixed(5)}",
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
