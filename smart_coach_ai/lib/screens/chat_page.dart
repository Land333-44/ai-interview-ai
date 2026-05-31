import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'notifications_page.dart';
import 'upload_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.sessionContext, this.sessionScore});

  static const String routeName = '/chat';

  final String? sessionContext;
  final int? sessionScore;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

String _messageText(Map<String, dynamic> msg) =>
    (msg['messageText'] ?? msg['message_text'] ?? '').toString();

String _messageTime(Map<String, dynamic> msg) =>
    (msg['timestamp'] ?? msg['created_at'] ?? msg['\$createdAt'] ?? '')
        .toString();

class _ChatPageState extends State<ChatPage> {
  final _auth = AuthService();
  final _db = DatabaseService();
  final _api = ApiService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  String? _userId;
  String _sessionId = '';
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;

  // Context injected from ResultsPage
  String? _sessionContext;
  int? _sessionScore;

  @override
  void initState() {
    super.initState();
    _sessionContext = widget.sessionContext;
    _sessionScore = widget.sessionScore;
    _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fallback: Read context args passed from legacy/Navigator settings
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _sessionContext ??= args['context']?.toString();
      _sessionScore ??= args['score'] as int?;
    }
  }

  Future<void> _init() async {
    final user = await _auth.getCurrentUser();
    if (user == null) return;
    _userId = user.$id;
    _sessionId =
        '${user.$id}_${DateTime.now().toIso8601String().substring(0, 10)}';
    await _loadMessages();

    if (_messages.isEmpty) {
      String greeting;
      if (_sessionContext != null && _sessionContext!.isNotEmpty) {
        final scoreStr =
            _sessionScore != null ? ' (score : $_sessionScore/100)' : '';
        greeting =
            'Salam ! Je suis Smart Coach AI. J\'ai analysé votre dernière session$scoreStr.\n\n'
            '"${_sessionContext!}"\n\n'
            'Que voulez-vous approfondir ou travailler ?';
      } else {
        greeting =
            'Salam ! Je suis Smart Coach AI. En quoi puis-je vous aider ? '
            'Voulez-vous pratiquer un entretien, une présentation ou un discours ?';
      }
      setState(() {
        _messages = [
          {
            'sender': 'ai',
            'message_text': greeting,
            'created_at': DateTime.now().toIso8601String(),
          },
        ];
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMessages() async {
    final msgs = await _db.getChatMessages(_sessionId);
    if (mounted) setState(() => _messages = msgs);
    _scrollToBottom();
  }

  List<Map<String, String>> _buildHistory() {
    final list = _messages
        .where((m) => _messageText(m).isNotEmpty)
        .map(
          (m) => {
            'role': m['sender'] == 'ai' ? 'assistant' : 'user',
            'content': _messageText(m),
          },
        )
        .toList();
    if (list.length <= 8) return list;
    return list.sublist(list.length - 8);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || _userId == null) return;

    _controller.clear();
    setState(() {
      _sending = true;
      _messages.add({
        'sender': 'user',
        'message_text': text,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    await _db.sendChatMessage(
      sessionId: _sessionId,
      userId: _userId!,
      sender: 'user',
      messageText: text,
    );

    final aiReply = await _api.chatWithCoach(
      text,
      history: _buildHistory(),
      sessionId: _sessionId,
    );

    if (aiReply.contains('unavailable') ||
        aiReply.contains('Redeploy') ||
        aiReply.contains('GROQ')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(aiReply),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    await _db.sendChatMessage(
      sessionId: _sessionId,
      userId: _userId!,
      sender: 'ai',
      messageText: aiReply,
    );

    if (mounted) {
      setState(() {
        _messages.add({
          'sender': 'ai',
          'message_text': aiReply,
          'created_at': DateTime.now().toIso8601String(),
        });
        _sending = false;
      });
      _scrollToBottom();
    }
  }

  void _openUploadTab(int tabIndex) {
    context.push(UploadPage.routeName, extra: tabIndex);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navIcon),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🧠', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coach IA',
                  style: AppTextStyles.title2.copyWith(
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      height: 6,
                      width: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'En ligne',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 9,
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.navIcon,
            ),
            onPressed: () => context.push(NotificationsPage.routeName),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildQuickChips(),
            if (_sessionScore != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        size: 14,
                        color: AppColors.skyDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Contexte session activé — Score : $_sessionScore/100',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.skyDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final msg = _messages[i];
                        final isAi = msg['sender'] == 'ai';
                        final time = _formatTime(_messageTime(msg));
                        if (isAi) {
                          return _CoachMessage(
                            text: _messageText(msg),
                            time: time,
                          );
                        } else {
                          return _UserMessage(
                            text: _messageText(msg),
                            time: time,
                          );
                        }
                      },
                    ),
            ),
            if (_sending)
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _TypingIndicator(),
                ),
              ),
            _MessageInput(
              controller: _controller,
              onSend: _sendMessage,
              sending: _sending,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _MediaChip(
              icon: Icons.mic_rounded,
              label: 'Audio',
              onTap: () => _openUploadTab(0),
            ),
            const SizedBox(width: 8),
            _MediaChip(
              icon: Icons.description_rounded,
              label: 'Texte',
              onTap: () => _openUploadTab(1),
            ),
            const SizedBox(width: 8),
            _MediaChip(
              icon: Icons.videocam_rounded,
              label: 'Vidéo',
              onTap: () => _openUploadTab(2),
            ),
            const SizedBox(width: 8),
            _MediaChip(
              icon: Icons.image_rounded,
              label: 'Photo',
              onTap: () => _openUploadTab(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaChip extends StatelessWidget {
  const _MediaChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.skyDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.skyDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachMessage extends StatelessWidget {
  const _CoachMessage({required this.text, required this.time});
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outline),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.psychology_rounded,
              color: AppColors.skyDark,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Text(
                    text,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.text,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    time,
                    style: AppTextStyles.caption.copyWith(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _UserMessage extends StatelessWidget {
  const _UserMessage({required this.text, required this.time});
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(0),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    text,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    time,
                    style: AppTextStyles.caption.copyWith(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.4).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.psychology_rounded,
            color: AppColors.skyDark,
            size: 14,
          ),
          const SizedBox(width: 8),
          FadeTransition(
            opacity: _anim,
            child: Text(
              'Coach IA est en train d\'écrire...',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.skyDark,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.onSend,
    required this.sending,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.outline),
              ),
              child: Center(
                child: TextField(
                  controller: controller,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: AppColors.text,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: 'Posez votre question...',
                    hintStyle: TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              height: 44,
              width: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
