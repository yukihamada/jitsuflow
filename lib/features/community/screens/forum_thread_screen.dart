import 'package:flutter/material.dart';
import '../models/forum_models.dart';

class ForumThreadScreen extends StatefulWidget {
  final ForumThread thread;

  const ForumThreadScreen({super.key, required this.thread});

  @override
  State<ForumThreadScreen> createState() => _ForumThreadScreenState();
}

class _ForumThreadScreenState extends State<ForumThreadScreen> {
  final _replyController = TextEditingController();
  late List<ForumReply> _replies;

  @override
  void initState() {
    super.initState();
    _replies = _buildMockReplies(widget.thread.id);
  }

  List<ForumReply> _buildMockReplies(String threadId) {
    return [
      ForumReply(
        id: '${threadId}_r1',
        threadId: threadId,
        body: 'とても参考になる投稿ありがとうございます！私も同じことで悩んでいました。先生に聞いてみたところ、基本姿勢をしっかり保つことが一番大切だと言っていました。',
        authorName: '青木誠',
        createdAt: DateTime(2025, 3, 14, 10, 30),
      ),
      ForumReply(
        id: '${threadId}_r2',
        threadId: threadId,
        body: '自分の経験では、相手の動きをよく観察することが重要です。最初はゆっくりと動作を確認しながら練習するのがおすすめですよ。',
        authorName: '西村さくら',
        createdAt: DateTime(2025, 3, 14, 14, 15),
      ),
      ForumReply(
        id: '${threadId}_r3',
        threadId: threadId,
        body: '道場でのスパーリングで実践してみてください。理論だけでなく、実際に体で覚えることが柔術の上達への近道だと思います！',
        authorName: '松田剛',
        createdAt: DateTime(2025, 3, 15, 9, 0),
      ),
    ];
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _replies.add(ForumReply(
        id: '${widget.thread.id}_r${_replies.length + 1}',
        threadId: widget.thread.id,
        body: text,
        authorName: '自分',
        createdAt: DateTime.now(),
      ));
      _replyController.clear();
    });
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    return name.characters.first;
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: Text(
          widget.thread.title,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOriginalPost(),
                const SizedBox(height: 20),
                _buildRepliesHeader(),
                const SizedBox(height: 12),
                ..._replies.map(_buildReplyCard),
              ],
            ),
          ),
          _buildReplyBar(),
        ],
      ),
    );
  }

  Widget _buildOriginalPost() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFDC2626),
                child: Text(
                  _initials(widget.thread.authorName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.thread.authorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _formatDate(widget.thread.createdAt),
                    style: const TextStyle(
                      color: Color(0xFFA1A1AA),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.thread.body,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesHeader() {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '返信 (${_replies.length}件)',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildReplyCard(ForumReply reply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFF3F3F46),
                child: Text(
                  _initials(reply.authorName),
                  style: const TextStyle(
                    color: Color(0xFFA1A1AA),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                reply.authorName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(reply.createdAt),
                style: const TextStyle(
                  color: Color(0xFFA1A1AA),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reply.body,
            style: const TextStyle(
              color: Color(0xFFD4D4D8),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        border: Border(top: BorderSide(color: Color(0xFF27272A))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '返信を入力...',
                hintStyle: const TextStyle(color: Color(0xFF71717A)),
                filled: true,
                fillColor: const Color(0xFF27272A),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendReply(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendReply,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
