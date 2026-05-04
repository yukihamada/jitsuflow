import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';
import '../services/iap_service.dart';

final _api = ApiClient();

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Map<String, dynamic>? _sub;
  bool _loading = true;
  bool _purchasing = false;
  final _iap = IapService();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _iap.onPurchaseSuccess = (purchase) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('購入完了！ありがとうございます'),
              backgroundColor: Color(0xFF16A34A)));
        setState(() => _purchasing = false);
        _loadStatus();
      }
    };
    _iap.onPurchaseError = (msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444)));
        setState(() => _purchasing = false);
      }
    };
    await _iap.init();
    await _loadStatus();
  }

  Future<void> _loadStatus() async {
    final data = await _api.getSubscription();
    if (mounted) setState(() { _sub = data; _loading = false; });
  }

  @override
  void dispose() {
    _iap.dispose();
    super.dispose();
  }

  bool get _isActive => _sub?['status'] == 'active';
  String get _plan => _sub?['plan'] as String? ?? 'free';
  int get _amount => (_sub?['amount'] as int?) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        title: const Text('サブスクリプション',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () => _iap.restorePurchases(),
            child: const Text('復元', style: TextStyle(color: Color(0xFF71717A), fontSize: 13)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)))
          : RefreshIndicator(
              color: const Color(0xFFDC2626),
              backgroundColor: const Color(0xFF18181B),
              onRefresh: _loadStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 24),
                    if (!_isActive) ...[
                      const Text('プランを選択',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('いつでもキャンセル可能',
                          style: TextStyle(color: Color(0xFF71717A), fontSize: 13)),
                      const SizedBox(height: 16),
                      if (_iap.products.isNotEmpty)
                        ..._buildIapPlans()
                      else ...[
                        _buildPlanCard('Founder', 980, '基本機能すべて', const Color(0xFF22C55E), 'jiuflow.founder.monthly'),
                        const SizedBox(height: 12),
                        _buildPlanCard('Regular', 1480, '全機能 + 優先サポート', const Color(0xFF3B82F6), 'jiuflow.regular.monthly'),
                        const SizedBox(height: 12),
                        _buildPlanCard('Pro', 2900, '全機能 + 1on1コンサル', const Color(0xFF7C3AED), 'jiuflow.pro.monthly'),
                      ],
                    ],
                    if (_purchasing)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: CircularProgressIndicator(color: Color(0xFFDC2626)),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildIapPlans() {
    final sorted = List<ProductDetails>.from(_iap.products)
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    final colors = [const Color(0xFF22C55E), const Color(0xFF3B82F6), const Color(0xFF7C3AED)];
    final descs = ['基本機能すべて', '全機能 + 優先サポート', '全機能 + 1on1コンサル'];
    return [
      for (int i = 0; i < sorted.length; i++) ...[
        _buildIapCard(sorted[i], colors[i % 3], descs[i % 3]),
        if (i < sorted.length - 1) const SizedBox(height: 12),
      ],
    ];
  }

  Widget _buildIapCard(ProductDetails product, Color color, String desc) {
    return GestureDetector(
      onTap: _purchasing ? null : () => _buyIap(product.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title.replaceAll(' (JiuFlow)', ''),
                      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Color(0xFF71717A), fontSize: 13)),
                ],
              ),
            ),
            Text(product.price,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _isActive
            ? const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF22C55E)])
            : const LinearGradient(colors: [Color(0xFF27272A), Color(0xFF3F3F46)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(_isActive ? Icons.verified : Icons.lock_outline, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(
              _isActive ? 'アクティブ' : '無料プラン',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            )),
          ]),
          const SizedBox(height: 8),
          if (_isActive) ...[
            Text('${_plan.toUpperCase()} プラン — ¥$_amount/月',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ] else
            const Text('有料プランに登録すると全機能が使えます',
                style: TextStyle(color: Colors.white60, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String name, int price, String desc, Color color, String productId) {
    return GestureDetector(
      onTap: _purchasing ? null : () => _buyOrCheckout(productId, name),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: Color(0xFF71717A), fontSize: 13)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('¥$price', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('/月', style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
          ]),
        ]),
      ),
    );
  }

  Future<void> _buyIap(String productId) async {
    setState(() => _purchasing = true);
    try {
      await _iap.buySubscription(productId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e'), backgroundColor: const Color(0xFFEF4444)));
        setState(() => _purchasing = false);
      }
    }
  }

  Future<void> _buyOrCheckout(String productId, String planName) async {
    // Try IAP first on iOS
    if (Platform.isIOS && _iap.available) {
      await _buyIap(productId);
      return;
    }
    // Fallback to Stripe web checkout
    setState(() => _loading = true);
    final url = await _api.createCheckoutSession();
    setState(() => _loading = false);
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('チェックアウトの作成に失敗しました'),
            backgroundColor: Color(0xFFEF4444)));
    }
  }
}
