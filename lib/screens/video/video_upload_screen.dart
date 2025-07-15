/**
 * 動画アップロード画面
 * インストラクターが技術動画をアップロードする画面
 */

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../services/api_service.dart';
import '../../widgets/common/loading_widget.dart';

class VideoUploadScreen extends StatefulWidget {
  const VideoUploadScreen({super.key});

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'basic';
  String _selectedDifficulty = 'beginner';
  String _selectedAccessType = 'members_only';
  
  PlatformFile? _selectedFile;
  Uint8List? _fileBytes;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final List<Map<String, String>> _categories = [
    {'value': 'basic', 'label': '基礎技術'},
    {'value': 'guard', 'label': 'ガード'},
    {'value': 'pass', 'label': 'パスガード'},
    {'value': 'submission', 'label': 'サブミッション'},
    {'value': 'sweep', 'label': 'スイープ'},
    {'value': 'takedown', 'label': 'テイクダウン'},
    {'value': 'escape', 'label': 'エスケープ'},
    {'value': 'drill', 'label': 'ドリル'},
    {'value': 'sparring', 'label': 'スパーリング'},
  ];

  final List<Map<String, String>> _difficulties = [
    {'value': 'beginner', 'label': '初級'},
    {'value': 'intermediate', 'label': '中級'},
    {'value': 'advanced', 'label': '上級'},
    {'value': 'expert', 'label': 'エキスパート'},
  ];

  final List<Map<String, String>> _accessTypes = [
    {'value': 'public', 'label': '全体公開'},
    {'value': 'members_only', 'label': 'メンバーのみ'},
    {'value': 'premium', 'label': 'プレミアム会員限定'},
    {'value': 'specific_students', 'label': '特定の生徒のみ'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // ファイルサイズチェック（1GB）
        if (file.size > 1024 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ファイルサイズは1GB以下にしてください')),
          );
          return;
        }

        setState(() {
          _selectedFile = file;
          _fileBytes = file.bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ファイル選択エラー: $e')),
      );
    }
  }

  Future<void> _uploadVideo() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // 1. アップロードURL取得
      final uploadUrlResponse = await _apiService.post(
        '/api/videos/upload-url',
        {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'category': _selectedCategory,
          'difficulty_level': _selectedDifficulty,
          'access_type': _selectedAccessType,
          'file_name': _selectedFile!.name,
          'file_size': _selectedFile!.size,
          'mime_type': _getMimeType(_selectedFile!.extension),
        },
      );

      final videoId = uploadUrlResponse['video_id'];
      final cloudflareKey = uploadUrlResponse['cloudflare_key'];

      // 2. ファイルアップロード（シミュレーション）
      // 実際のアップロードはCloudflare R2 APIを使用
      setState(() => _uploadProgress = 0.3);
      
      // ここで実際のファイルアップロードを実行
      // await _uploadToR2(uploadUrl, _fileBytes!);
      
      setState(() => _uploadProgress = 0.9);

      // 3. アップロード完了処理
      await _apiService.post(
        '/api/videos/$videoId/complete-upload',
        {
          'cloudflare_key': cloudflareKey,
        },
      );

      setState(() => _uploadProgress = 1.0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('動画のアップロードが完了しました')),
      );

      // フォームリセット
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedFile = null;
        _fileBytes = null;
        _selectedCategory = 'basic';
        _selectedDifficulty = 'beginner';
        _selectedAccessType = 'members_only';
      });

      // 動画一覧画面に戻る
      Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アップロードエラー: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  String _getMimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      default:
        return 'video/mp4';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('動画アップロード'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isUploading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 16),
                Text('アップロード中... ${(_uploadProgress * 100).toInt()}%'),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ファイル選択
                  Card(
                    child: InkWell(
                      onTap: _selectFile,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              _selectedFile != null ? Icons.videocam : Icons.cloud_upload,
                              size: 64,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFile != null
                                ? _selectedFile!.name
                                : 'タップして動画を選択',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            if (_selectedFile != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'サイズ: ${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // タイトル
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'タイトル *',
                      hintText: '動画のタイトルを入力',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'タイトルを入力してください';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 説明
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: '説明',
                      hintText: '動画の説明を入力',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // カテゴリー
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'カテゴリー',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) => 
                      DropdownMenuItem(
                        value: category['value'],
                        child: Text(category['label']!),
                      ),
                    ).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 難易度
                  DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    decoration: const InputDecoration(
                      labelText: '難易度',
                      border: OutlineInputBorder(),
                    ),
                    items: _difficulties.map((difficulty) => 
                      DropdownMenuItem(
                        value: difficulty['value'],
                        child: Text(difficulty['label']!),
                      ),
                    ).toList(),
                    onChanged: (value) => setState(() => _selectedDifficulty = value!),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // アクセス権限
                  DropdownButtonFormField<String>(
                    value: _selectedAccessType,
                    decoration: const InputDecoration(
                      labelText: 'アクセス権限',
                      border: OutlineInputBorder(),
                    ),
                    items: _accessTypes.map((type) => 
                      DropdownMenuItem(
                        value: type['value'],
                        child: Text(type['label']!),
                      ),
                    ).toList(),
                    onChanged: (value) => setState(() => _selectedAccessType = value!),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // アップロードボタン
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _selectedFile == null ? null : _uploadVideo,
                      icon: const Icon(Icons.upload),
                      label: const Text('アップロード'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 注意事項
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'アップロード時の注意',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• ファイルサイズは1GB以下にしてください\n'
                            '• 対応形式: MP4, MOV, AVI, WebM\n'
                            '• アップロード後の処理に時間がかかる場合があります\n'
                            '• 不適切なコンテンツはアップロードしないでください',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}