import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const Color burgundy = Color(0xFF800020);
  static const Color darkGrey = Color(0xFF2B2B2B);

  static const String phoneNumber = "0599314027";
  static const String email = "LYM2004@gmail.com";
  static const String whatsappNumber = "+97599314027";
  static const String locationUrl = "https://maps.google.com/?q=Palestine";

  Future<void> _open(Uri uri, BuildContext context) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't open the link")));
    }
  }

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: burgundy.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: burgundy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: darkGrey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(title: const Text("Contact Us"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black12),
            ),
            child: const Row(
              children: [
                Icon(Icons.support_agent, color: burgundy),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Need help? Reach us through any of the options below.",
                    style: TextStyle(
                      color: darkGrey,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _actionCard(
            context: context,
            icon: Icons.phone,
            title: "Call us",
            subtitle: phoneNumber,
            onTap: () => _open(Uri.parse("tel:$phoneNumber"), context),
          ),
          const SizedBox(height: 10),
          _actionCard(
            context: context,
            icon: Icons.email,
            title: "Email",
            subtitle: email,
            onTap: () => _open(
              Uri.parse("mailto:$email?subject=Support%20Request"),
              context,
            ),
          ),
          const SizedBox(height: 10),
          _actionCard(
            context: context,
            icon: Icons.chat,
            title: "WhatsApp",
            subtitle: whatsappNumber,
            onTap: () => _open(
              Uri.parse("https://wa.me/${whatsappNumber.replaceAll("+", "")}"),
              context,
            ),
          ),
          const SizedBox(height: 10),
          _actionCard(
            context: context,
            icon: Icons.location_on,
            title: "Location",
            subtitle: "Open in Google Maps",
            onTap: () => _open(Uri.parse(locationUrl), context),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Working hours",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: darkGrey,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 18, color: burgundy),
                    SizedBox(width: 8),
                    Text(
                      "Sun - Thu: 9:00 AM - 6:00 PM",
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
