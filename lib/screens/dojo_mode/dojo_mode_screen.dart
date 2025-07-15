import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dojo_mode/dojo_mode_bloc.dart';
import '../../blocs/dojo_mode/dojo_mode_event.dart';
import '../../blocs/dojo_mode/dojo_mode_state.dart';
import 'pos_screen.dart';
import 'rental_screen.dart';
import 'sparring_recording_screen.dart';
import 'analytics_screen.dart';

class DojoModeScreen extends StatefulWidget {
  final int dojoId;
  
  const DojoModeScreen({
    super.key,
    required this.dojoId,
  });

  @override
  State<DojoModeScreen> createState() => _DojoModeScreenState();
}

class _DojoModeScreenState extends State<DojoModeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DojoModeBloc>().add(LoadDojoModeData(widget.dojoId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DojoModeBloc, DojoModeState>(
      builder: (context, state) {
        if (state is DojoModeLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (state is DojoModeError) {
          return Scaffold(
            appBar: AppBar(title: const Text('道場モード')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('エラー: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<DojoModeBloc>().add(LoadDojoModeData(widget.dojoId));
                    },
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (state is DojoModeLoaded) {
          return Scaffold(
            appBar: AppBar(
              title: Text(state.isDojoMode ? '道場モード' : 'JitsuFlow'),
              backgroundColor: state.isDojoMode ? Colors.orange : const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              actions: [
                // Mode Switch
                Switch(
                  value: state.isDojoMode,
                  onChanged: (value) {
                    if (value) {
                      context.read<DojoModeBloc>().add(SwitchToDojoMode());
                    } else {
                      context.read<DojoModeBloc>().add(SwitchToUserMode());
                    }
                  },
                  activeColor: Colors.white,
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: state.isDojoMode ? _buildDojoModeView(state) : _buildUserModeView(state),
          );
        }
        
        return const Scaffold(
          body: Center(child: Text('Unknown state')),
        );
      },
    );
  }

  Widget _buildDojoModeView(DojoModeLoaded state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange, Colors.deepOrange],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Today's Sales Summary
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.store,
                            size: 32,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '本日の売上',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (state.isRecording)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fiber_manual_record,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '録画中',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.formattedTodayTotal,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${state.todaySales.length}件の取引',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Function Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildFunctionCard(
                      icon: Icons.point_of_sale,
                      title: 'POS',
                      subtitle: '物販・支払い',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => POSScreen(dojoId: widget.dojoId),
                          ),
                        );
                      },
                    ),
                    _buildFunctionCard(
                      icon: Icons.shopping_bag,
                      title: 'レンタル',
                      subtitle: '道着・用具',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RentalScreen(dojoId: widget.dojoId),
                          ),
                        );
                      },
                    ),
                    _buildFunctionCard(
                      icon: Icons.videocam,
                      title: 'スパーリング録画',
                      subtitle: '練習・試合記録',
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SparringRecordingScreen(
                              dojoId: widget.dojoId,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildFunctionCard(
                      icon: Icons.analytics,
                      title: '経営分析',
                      subtitle: '売上・利益',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnalyticsScreen(
                              dojoId: widget.dojoId,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserModeView(DojoModeLoaded state) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_martial_arts,
            size: 120,
            color: Color(0xFF1B5E20),
          ),
          SizedBox(height: 24),
          Text(
            'ユーザーモード',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '右上のスイッチで道場モードに切り替え',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}