import 'package:flutter/material.dart';
import '../../themes/colorful_theme.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final List<Message> _messages = [
    Message(
      id: '1',
      senderName: 'YAWARA道場',
      senderAvatar: 'Y',
      lastMessage: '明日のクラスは通常通り開催します。',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      unreadCount: 2,
      isGroup: true,
    ),
    Message(
      id: '2',
      senderName: '村田良蔵 先生',
      senderAvatar: '村',
      lastMessage: '先日の技術について質問がありましたら...',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 0,
      isGroup: false,
    ),
    Message(
      id: '3',
      senderName: 'システム通知',
      senderAvatar: 'S',
      lastMessage: '予約確認：7/15(土) 19:00〜のクラス',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      unreadCount: 1,
      isGroup: false,
    ),
    Message(
      id: '4',
      senderName: '柔術仲間グループ',
      senderAvatar: 'G',
      lastMessage: '田中: 今度の大会出る人いますか？',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 5,
      isGroup: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メッセージ'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 検索機能
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showNewMessageDialog(),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _buildMessageTile(message);
        },
      ),
    );
  }

  Widget _buildMessageTile(Message message) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: ColorfulTheme.getChipColor(
            message.senderName.hashCode % 6,
          ),
          child: Text(
            message.senderAvatar,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Row(
          children: [
            if (message.isGroup)
              const Icon(
                Icons.group,
                size: 16,
                color: Colors.grey,
              ),
            if (message.isGroup) const SizedBox(width: 4),
            Expanded(
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message.lastMessage,
                  style: TextStyle(
                    color: message.unreadCount > 0 
                        ? Colors.black87 
                        : Colors.grey[600],
                    fontWeight: message.unreadCount > 0 
                        ? FontWeight.w500 
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (message.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        onTap: () => _openChat(message),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  void _openChat(Message message) {
    // TODO: チャット画面への遷移
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${message.senderName}とのチャットを開きます'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showNewMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しいメッセージ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF1B5E20)),
              title: const Text('個人メッセージ'),
              subtitle: const Text('道場のメンバーに直接メッセージ'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 個人選択画面へ
              },
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Color(0xFF1B5E20)),
              title: const Text('グループ作成'),
              subtitle: const Text('複数人でのグループチャット'),
              onTap: () {
                Navigator.pop(context);
                // TODO: グループ作成画面へ
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent, color: Color(0xFF1B5E20)),
              title: const Text('サポートに連絡'),
              subtitle: const Text('技術的な問題や質問'),
              onTap: () {
                Navigator.pop(context);
                // TODO: サポートチャットへ
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String id;
  final String senderName;
  final String senderAvatar;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final bool isGroup;

  Message({
    required this.id,
    required this.senderName,
    required this.senderAvatar,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.isGroup,
  });
}