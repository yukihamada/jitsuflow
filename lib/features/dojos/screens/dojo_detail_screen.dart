import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/dojo_model.dart';

class DojoDetailScreen extends StatelessWidget {
  final DojoModel dojo;
  const DojoDetailScreen({super.key, required this.dojo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(dojo.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: const Center(
                child: Text('🏫', style: TextStyle(fontSize: 64)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              dojo.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: Color(0xFF71717A)),
                const SizedBox(width: 4),
                Text(
                  [dojo.prefecture, dojo.city, dojo.address]
                      .where((s) => s != null)
                      .join(' '),
                  style: const TextStyle(
                    color: Color(0xFFA1A1AA),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (dojo.description != null) ...[
              const Text(
                '道場について',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: Text(
                  dojo.description!,
                  style: const TextStyle(
                    color: Color(0xFFD4D4D8),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (dojo.memberCount != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people,
                        color: Color(0xFFDC2626), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '会員数: ${dojo.memberCount}名',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (dojo.website != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(dojo.website!);
                    if (uri != null) await launchUrl(uri);
                  },
                  icon: const Icon(Icons.open_in_browser,
                      color: Color(0xFFDC2626)),
                  label: const Text(
                    'ウェブサイトを見る',
                    style: TextStyle(color: Color(0xFFDC2626)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('クラス予約機能は近日公開予定です')),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'クラスを予約する',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
