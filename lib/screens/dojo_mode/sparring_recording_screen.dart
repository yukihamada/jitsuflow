import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dojo_mode/dojo_mode_bloc.dart';
import '../../blocs/dojo_mode/dojo_mode_event.dart';
import '../../blocs/dojo_mode/dojo_mode_state.dart';

class SparringRecordingScreen extends StatefulWidget {
  final int dojoId;
  
  const SparringRecordingScreen({
    super.key,
    required this.dojoId,
  });

  @override
  State<SparringRecordingScreen> createState() => _SparringRecordingScreenState();
}

class _SparringRecordingScreenState extends State<SparringRecordingScreen> {
  int? _participant1Id;
  int? _participant2Id;
  String _selectedRuleSet = 'ibjjf';
  
  final List<Map<String, dynamic>> _demoMembers = [
    {'id': 1, 'name': 'デモユーザー', 'belt': '白帯'},
    {'id': 2, 'name': '村田良蔵', 'belt': '黒帯'},
    {'id': 3, 'name': '廣鰭翔大', 'belt': '茶帯'},
    {'id': 4, 'name': '佐藤正幸', 'belt': '紫帯'},
    {'id': 5, 'name': '堰本祐希', 'belt': '紫帯'},
    {'id': 6, 'name': '諸澤陽斗', 'belt': '黒帯'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スパーリング録画'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<DojoModeBloc, DojoModeState>(
        builder: (context, state) {
          if (state is DojoModeLoaded) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.isRecording)
                    _buildRecordingView(state)
                  else
                    _buildSetupView(),
                ],
              ),
            );
          }
          
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildSetupView() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recording Setup Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.videocam,
                          color: Colors.red,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'スパーリング録画設定',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Participant 1
                    const Text(
                      '参加者1',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _participant1Id,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '参加者を選択',
                      ),
                      items: _demoMembers.map((member) {
                        return DropdownMenuItem<int>(
                          value: member['id'],
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getBeltColor(member['belt']),
                                radius: 12,
                                child: Text(
                                  member['name'][0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${member['name']} (${member['belt']})'),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _participant1Id = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Participant 2
                    const Text(
                      '参加者2',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _participant2Id,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '参加者を選択',
                      ),
                      items: _demoMembers.map((member) {
                        return DropdownMenuItem<int>(
                          value: member['id'],
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getBeltColor(member['belt']),
                                radius: 12,
                                child: Text(
                                  member['name'][0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${member['name']} (${member['belt']})'),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _participant2Id = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Rule Set
                    const Text(
                      'ルールセット',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRuleSet,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'ibjjf',
                          child: Text('IBJJF'),
                        ),
                        DropdownMenuItem(
                          value: 'adcc',
                          child: Text('ADCC'),
                        ),
                        DropdownMenuItem(
                          value: 'submission_only',
                          child: Text('サブミッションオンリー'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRuleSet = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Start Recording Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _canStartRecording() ? _startRecording : null,
                        icon: const Icon(Icons.fiber_manual_record),
                        label: const Text(
                          '録画開始',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recent Recordings
            _buildRecentRecordings(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingView(DojoModeLoaded state) {
    final duration = state.currentRecordingDuration;
    final participant1 = _demoMembers.firstWhere((m) => m['id'] == _participant1Id);
    final participant2 = _demoMembers.firstWhere((m) => m['id'] == _participant2Id);
    
    return Expanded(
      child: Column(
        children: [
          // Recording Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '録画中',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  duration != null ? _formatDuration(duration) : '00:00',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Participants
          Row(
            children: [
              Expanded(
                child: _buildParticipantCard(participant1, true),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(
                child: _buildParticipantCard(participant2, false),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Camera View Placeholder
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam,
                      size: 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'カメラビュー',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stop Recording Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _showStopRecordingDialog(),
              icon: const Icon(Icons.stop),
              label: const Text(
                '録画終了',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(Map<String, dynamic> participant, bool isLeft) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: _getBeltColor(participant['belt']),
              radius: 30,
              child: Text(
                participant['name'][0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              participant['name'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              participant['belt'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecordings() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '最近の録画',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.play_circle_outline, color: Colors.red),
                  title: Text('スパーリング ${index + 1}'),
                  subtitle: Text('${DateTime.now().subtract(Duration(days: index)).toString().split(' ')[0]} • 5:30'),
                  trailing: const Icon(Icons.more_vert),
                  onTap: () {
                    // TODO: Open video player
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _canStartRecording() {
    return _participant1Id != null && 
           _participant2Id != null && 
           _participant1Id != _participant2Id;
  }

  void _startRecording() {
    context.read<DojoModeBloc>().add(StartSparringRecording(
      dojoId: widget.dojoId,
      participant1Id: _participant1Id!,
      participant2Id: _participant2Id!,
      ruleSet: _selectedRuleSet,
    ));
  }

  void _showStopRecordingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('録画終了'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('勝者を選択してください（任意）:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '勝者を選択',
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('引き分け'),
                ),
                ..._demoMembers.where((m) => 
                  m['id'] == _participant1Id || m['id'] == _participant2Id
                ).map((member) {
                  return DropdownMenuItem<int>(
                    value: member['id'],
                    child: Text(member['name']),
                  );
                }),
              ],
              onChanged: (value) {
                // Store winner selection
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DojoModeBloc>().add(StopSparringRecording(
                finishType: 'decision',
              ));
            },
            child: const Text('終了'),
          ),
        ],
      ),
    );
  }

  Color _getBeltColor(String belt) {
    switch (belt) {
      case '黒帯':
        return Colors.black;
      case '茶帯':
        return Colors.brown;
      case '紫帯':
        return Colors.purple;
      case '青帯':
        return Colors.blue;
      case '白帯':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}