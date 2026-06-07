import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final String? matchContext;
  final bool autoAnalyze;
  const ChatScreen({super.key, this.matchContext, this.autoAnalyze = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.autoAnalyze && widget.matchContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final token = context.read<AuthProvider>().token;
        context.read<ChatProvider>().greet(token, widget.matchContext!);
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    final token = context.read<AuthProvider>().token;
    context
        .read<ChatProvider>()
        .send(text, token, matchContext: widget.matchContext);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    if (chat.messages.isNotEmpty || chat.sending) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _VeraAvatar(size: 28),
            SizedBox(width: 8),
            Text('Vera IA'),
          ],
        ),
        actions: [
          if (chat.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Limpiar chat',
              onPressed: () => context.read<ChatProvider>().clear(),
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.matchContext != null)
            _ContextBanner(context: widget.matchContext!),
          Expanded(
            child: chat.messages.isEmpty && !chat.sending
                ? _EmptyState(matchContext: widget.matchContext)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    itemCount:
                        chat.messages.length + (chat.sending ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == chat.messages.length) {
                        return const _TypingBubble();
                      }
                      final msg = chat.messages[i];
                      return _MessageBubble(
                        role: msg.role,
                        content: msg.content,
                      );
                    },
                  ),
          ),
          if (chat.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                chat.error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          _InputBar(
            controller: _controller,
            sending: chat.sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

class _VeraAvatar extends StatelessWidget {
  final double size;
  const _VeraAvatar({this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPurple, kPurpleDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.55),
    );
  }
}

class _ContextBanner extends StatelessWidget {
  final String context;
  const _ContextBanner({required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: kPurpleDark.withAlpha(30),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            this.context.contains('Deporte: football')
                ? Icons.sports_soccer
                : Icons.sports_baseball,
            color: kPurple,
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              this.context,
              style: const TextStyle(color: kPurple, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? matchContext;
  const _EmptyState({this.matchContext});

  bool get _isFootball => matchContext?.contains('Deporte: football') == true;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _VeraAvatar(size: 64),
          const SizedBox(height: 20),
          const Text(
            'Hola, soy Vera',
            style: TextStyle(
                color: kText, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu asistente de pronósticos deportivos.\nPregúntame sobre cualquier partido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _isFootball
                ? const [
                    _SuggestionChip('¿Quién gana este partido?'),
                    _SuggestionChip('¿Qué dice el ranking FIFA?'),
                    _SuggestionChip('¿Es posible el empate?'),
                  ]
                : const [
                    _SuggestionChip('¿Cómo funciona el análisis?'),
                    _SuggestionChip('¿Qué significa confianza baja?'),
                    _SuggestionChip('¿Cuál equipo favorito hoy?'),
                  ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  const _SuggestionChip(this.text);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final token = context.read<AuthProvider>().token;
        context.read<ChatProvider>().send(text, token);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kPurple.withAlpha(80)),
        ),
        child: Text(text,
            style: const TextStyle(color: kPurple, fontSize: 12)),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String role;
  final String content;
  const _MessageBubble({required this.role, required this.content});

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _VeraAvatar(size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? kPurpleDark : kCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: isUser ? Colors.white : kText,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _VeraAvatar(size: 28),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final offset = ((_anim.value * 3) - i).clamp(0.0, 1.0);
                    final opacity = (offset < 0.5
                            ? offset * 2
                            : (1 - offset) * 2)
                        .clamp(0.3, 1.0);
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      child: Opacity(
                        opacity: opacity,
                        child: const CircleAvatar(
                          radius: 4,
                          backgroundColor: kMuted,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _InputBar(
      {required this.controller,
      required this.sending,
      required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kSurface,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Pregúntale a Vera...',
                hintStyle: const TextStyle(color: kMuted, fontSize: 14),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: kCard,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: sending ? kMuted : kPurple,
                shape: BoxShape.circle,
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
