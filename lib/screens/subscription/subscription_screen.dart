import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../services/api_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const Color _primaryGreen = Color(0xFF1B5E20);

  Map<String, dynamic>? _subscriptionStatus;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final status = await ApiService.getSubscriptionStatus();
      if (mounted) {
        setState(() {
          _subscriptionStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Default to free plan when API fails
          _subscriptionStatus = {
            'plan': 'free',
            'status': 'active',
          };
          _isLoading = false;
        });
      }
    }
  }

  String get _currentPlan =>
      _subscriptionStatus?['plan'] as String? ?? 'free';

  String get _currentStatus =>
      _subscriptionStatus?['status'] as String? ?? 'active';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント'),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSubscriptionStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 24),
                    _buildCurrentPlanSection(),
                    const SizedBox(height: 24),
                    _buildPlanCards(),
                    const SizedBox(height: 24),
                    _buildSettingsSection(),
                    const SizedBox(height: 24),
                    _buildLogoutButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile Card
  // ---------------------------------------------------------------------------

  Widget _buildProfileCard() {
    final authState = context.watch<AuthBloc>().state;
    String userName = 'ユーザー名';
    String userEmail = 'user@example.com';

    if (authState is AuthSuccess) {
      userName = authState.user.name;
      userEmail = authState.user.email;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: _primaryGreen,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              userEmail,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Current Plan Section
  // ---------------------------------------------------------------------------

  Widget _buildCurrentPlanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'サブスクリプション',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildPlanBadge(_currentPlan),
                    const Spacer(),
                    if (_currentPlan != 'free')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _currentStatus == 'active'
                              ? Colors.green[50]
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentStatus == 'active'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        child: Text(
                          _currentStatus == 'active' ? '有効' : 'キャンセル済',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _currentStatus == 'active'
                                ? Colors.green[800]
                                : Colors.orange[800],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '現在のプラン特典',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._buildCurrentFeatures(),
                if (_currentPlan != 'free' && _currentStatus == 'active') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : _confirmCancelSubscription,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('サブスクリプションをキャンセル'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanBadge(String plan) {
    Color bgColor;
    String label;
    switch (plan) {
      case 'premium':
        bgColor = Colors.amber;
        label = 'プレミアムプラン';
        break;
      case 'annual':
        bgColor = _primaryGreen;
        label = '年間プラン';
        break;
      default:
        bgColor = Colors.grey;
        label = 'フリープラン';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _buildCurrentFeatures() {
    if (_currentPlan == 'free') {
      return [
        _buildFeatureRow(Icons.check, Colors.green, '週2回の予約'),
        _buildFeatureRow(Icons.check, Colors.green, '基本動画の視聴'),
        _buildFeatureRow(Icons.close, Colors.red, 'プレミアム動画の視聴'),
        _buildFeatureRow(Icons.close, Colors.red, 'ライブ配信への参加'),
        _buildFeatureRow(Icons.close, Colors.red, '特別セミナーへの招待'),
      ];
    }
    return [
      _buildFeatureRow(Icons.check, Colors.green, '無制限の予約'),
      _buildFeatureRow(Icons.check, Colors.green, '基本動画の視聴'),
      _buildFeatureRow(Icons.check, Colors.green, 'プレミアム動画の視聴'),
      _buildFeatureRow(Icons.check, Colors.green, 'ライブ配信への参加'),
      _buildFeatureRow(Icons.check, Colors.green, '特別セミナーへの招待'),
    ];
  }

  Widget _buildFeatureRow(IconData icon, Color iconColor, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Plan Cards
  // ---------------------------------------------------------------------------

  Widget _buildPlanCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'プランを選択',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildPlanCard(
          planId: 'free',
          name: 'フリープラン',
          price: '¥0',
          period: '月',
          description: '柔術を始めたばかりの方に',
          features: [
            '週2回までのクラス予約',
            '基本テクニック動画の視聴',
            'スケジュール確認',
            'コミュニティアクセス',
          ],
          color: Colors.grey,
          isCurrent: _currentPlan == 'free',
        ),
        const SizedBox(height: 12),
        _buildPlanCard(
          planId: 'premium',
          priceId: 'price_jitsuflow_premium_monthly',
          name: 'プレミアムプラン',
          price: '¥980',
          period: '月',
          description: '本格的にトレーニングする方に',
          features: [
            '無制限のクラス予約',
            'すべての動画にアクセス',
            'ライブ配信への参加',
            '特別セミナーへの招待',
            '練習記録の詳細分析',
          ],
          color: Colors.amber,
          isCurrent: _currentPlan == 'premium',
          isRecommended: true,
          trialText: '初回1ヶ月間無料',
        ),
        const SizedBox(height: 12),
        _buildPlanCard(
          planId: 'annual',
          priceId: 'price_jitsuflow_premium_annual',
          name: '年間プラン',
          price: '¥9,996',
          period: '年',
          description: '長期的に続ける方に最もお得',
          features: [
            'プレミアムプランの全特典',
            '年払いで15%OFF',
            '月額換算 ¥833/月',
            '優先サポート',
          ],
          color: _primaryGreen,
          isCurrent: _currentPlan == 'annual',
          savingsText: '年間 ¥1,764 お得',
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String planId,
    String? priceId,
    required String name,
    required String price,
    required String period,
    required String description,
    required List<String> features,
    required Color color,
    required bool isCurrent,
    bool isRecommended = false,
    String? trialText,
    String? savingsText,
  }) {
    return Card(
      elevation: isCurrent ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          if (isRecommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Text(
                'おすすめ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '現在のプラン',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '/$period',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (trialText != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trialText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (savingsText != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      savingsText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(feature, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                )),
                if (!isCurrent && planId != 'free') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => _showSubscribeDialog(planId, priceId!, name, price, period),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _currentPlan == 'free'
                                      ? 'このプランに登録'
                                      : 'プランを変更',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Subscribe Dialog
  // ---------------------------------------------------------------------------

  void _showSubscribeDialog(
    String planId,
    String priceId,
    String planName,
    String price,
    String period,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Text(planName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$planName に登録します。',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('料金', style: TextStyle(fontSize: 14)),
                  Text(
                    '$price/$period',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Stripeによる安全な決済で処理されます。',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'いつでもキャンセル可能です。',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _processSubscription(priceId, planName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('登録する'),
          ),
        ],
      ),
    );
  }

  Future<void> _processSubscription(String priceId, String planName) async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // In production this would open Stripe's payment sheet
      // to collect paymentMethodId, then call createSubscription.
      // For now we simulate with a demo payment method ID.
      await ApiService.createSubscription(
        priceId: priceId,
        paymentMethodId: 'pm_demo_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$planName に登録しました'),
            backgroundColor: _primaryGreen,
          ),
        );
        // Reload status to reflect the change
        await _loadSubscriptionStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登録に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Cancel Subscription
  // ---------------------------------------------------------------------------

  void _confirmCancelSubscription() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('サブスクリプションのキャンセル'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('サブスクリプションをキャンセルしますか？'),
            SizedBox(height: 12),
            Text(
              '現在の請求期間が終了するまで引き続きプレミアム機能をご利用いただけます。',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('戻る'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _cancelSubscription();
            },
            child: const Text(
              'キャンセルする',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSubscription() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await ApiService.cancelSubscription();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('サブスクリプションをキャンセルしました'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadSubscriptionStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('キャンセルに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Settings Section
  // ---------------------------------------------------------------------------

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '設定',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _SettingsItem(
          icon: Icons.notifications,
          title: '通知設定',
          onTap: () {
            // Navigate to notification settings
          },
        ),
        _SettingsItem(
          icon: Icons.privacy_tip,
          title: 'プライバシーポリシー',
          onTap: () {
            // Navigate to privacy policy
          },
        ),
        _SettingsItem(
          icon: Icons.help,
          title: 'ヘルプ・サポート',
          onTap: () {
            // Navigate to help
          },
        ),
        _SettingsItem(
          icon: Icons.info,
          title: 'アプリについて',
          onTap: () {
            // Show about dialog
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Logout Button
  // ---------------------------------------------------------------------------

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () {
          _showLogoutDialog(context);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'ログアウト',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'ログアウト',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings Item Widget
// ---------------------------------------------------------------------------

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF1B5E20),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
