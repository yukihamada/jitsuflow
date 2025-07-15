import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/member/member_bloc.dart';
import '../../models/member.dart';
import '../../widgets/common/loading_widget.dart';

class MemberEditScreen extends StatefulWidget {
  final Member member;

  const MemberEditScreen({
    super.key,
    required this.member,
  });

  @override
  State<MemberEditScreen> createState() => _MemberEditScreenState();
}

class _MemberEditScreenState extends State<MemberEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  
  String? _selectedBeltRank;
  int? _selectedDojoId;

  final List<String> _beltRanks = ['white', 'blue', 'purple', 'brown', 'black'];
  
  final List<Map<String, dynamic>> _dojos = [
    {'id': 1, 'name': 'YAWARA JIU-JITSU ACADEMY'},
    {'id': 2, 'name': 'Over Limit Sapporo'},
    {'id': 3, 'name': 'スイープ'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _phoneController = TextEditingController(text: widget.member.phone ?? '');
    _selectedBeltRank = widget.member.beltRank;
    _selectedDojoId = widget.member.primaryDojoId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メンバー情報編集'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<MemberBloc, MemberState>(
        listener: (context, state) {
          if (state is MemberUpdateSuccess) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('メンバー情報を更新しました'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is MemberFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '基本情報',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Email (read-only)
                          TextFormField(
                            initialValue: widget.member.email,
                            decoration: const InputDecoration(
                              labelText: 'メールアドレス',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            enabled: false,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: '名前',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '名前を入力してください';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: '電話番号',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Belt and Dojo
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '帯と所属',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedBeltRank,
                            decoration: const InputDecoration(
                              labelText: '帯',
                              prefixIcon: Icon(Icons.military_tech),
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('選択してください'),
                            items: _beltRanks.map((belt) {
                              return DropdownMenuItem(
                                value: belt,
                                child: Text(_getBeltDisplay(belt)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBeltRank = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: _selectedDojoId,
                            decoration: const InputDecoration(
                              labelText: '主所属道場',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('選択してください'),
                            items: _dojos.map((dojo) {
                              return DropdownMenuItem(
                                value: dojo['id'] as int,
                                child: Text(dojo['name'] as String),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDojoId = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Information (read-only)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ステータス情報',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.admin_panel_settings,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ロール: ${widget.member.roleDisplay}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.toggle_on,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ステータス: ${widget.member.statusDisplay}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '※ ロールとステータスの変更は詳細画面から行ってください',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: state is MemberLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state is MemberLoading
                          ? const LoadingWidget(color: Colors.white)
                          : const Text(
                              '変更を保存',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<MemberBloc>().add(
        MemberUpdateRequested(
          memberId: widget.member.id,
          name: _nameController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          beltRank: _selectedBeltRank,
          primaryDojoId: _selectedDojoId,
        ),
      );
    }
  }

  String _getBeltDisplay(String belt) {
    switch (belt) {
      case 'white':
        return '白帯';
      case 'blue':
        return '青帯';
      case 'purple':
        return '紫帯';
      case 'brown':
        return '茶帯';
      case 'black':
        return '黒帯';
      default:
        return belt;
    }
  }
}