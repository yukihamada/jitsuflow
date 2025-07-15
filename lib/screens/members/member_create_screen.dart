import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/member/member_bloc.dart';
import '../../widgets/common/loading_widget.dart';

class MemberCreateScreen extends StatefulWidget {
  const MemberCreateScreen({super.key});

  @override
  State<MemberCreateScreen> createState() => _MemberCreateScreenState();
}

class _MemberCreateScreenState extends State<MemberCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedRole = 'user';
  String? _selectedBeltRank;
  int? _selectedDojoId;

  final List<String> _roles = ['user', 'instructor', 'admin'];
  final List<String> _beltRanks = ['white', 'blue', 'purple', 'brown', 'black'];
  
  final List<Map<String, dynamic>> _dojos = [
    {'id': 1, 'name': 'YAWARA JIU-JITSU ACADEMY'},
    {'id': 2, 'name': 'Over Limit Sapporo'},
    {'id': 3, 'name': 'スイープ'},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新規メンバー登録'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<MemberBloc, MemberState>(
        listener: (context, state) {
          if (state is MemberCreateSuccess) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('メンバーを登録しました'),
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
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'メールアドレス',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'メールアドレスを入力してください';
                              }
                              if (!value.contains('@')) {
                                return '有効なメールアドレスを入力してください';
                              }
                              return null;
                            },
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
                              labelText: '電話番号（任意）',
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

                  // Role and Belt
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
                            'ロールと帯',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'ロール',
                              prefixIcon: Icon(Icons.admin_panel_settings),
                              border: OutlineInputBorder(),
                            ),
                            items: _roles.map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(_getRoleDisplay(role)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedBeltRank,
                            decoration: const InputDecoration(
                              labelText: '帯（任意）',
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dojo Affiliation
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
                            '所属道場',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: _selectedDojoId,
                            decoration: const InputDecoration(
                              labelText: '主所属道場（任意）',
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
                              'メンバーを登録',
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
        MemberCreateRequested(
          email: _emailController.text,
          name: _nameController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          role: _selectedRole,
          beltRank: _selectedBeltRank,
          primaryDojoId: _selectedDojoId,
        ),
      );
    }
  }

  String _getRoleDisplay(String role) {
    switch (role) {
      case 'admin':
        return '管理者';
      case 'instructor':
        return 'インストラクター';
      case 'user':
        return '一般会員';
      default:
        return role;
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