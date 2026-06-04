import 'package:flutter/foundation.dart';
import '../core/api_client.dart';

class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  const ChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _sending = false;
  String? _error;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get sending => _sending;
  String? get error => _error;

  Future<void> send(String text, String? token, {String? matchContext}) async {
    if (text.trim().isEmpty || _sending) return;

    _messages.add(ChatMessage(role: 'user', content: text.trim()));
    _sending = true;
    _error = null;
    notifyListeners();

    try {
      final body = {
        'messages': _messages.map((m) => m.toJson()).toList(),
        if (matchContext != null) 'match_context': matchContext,
      };
      final data = await ApiClient(token: token).post('/api/chat', body);
      _messages.add(ChatMessage(role: 'assistant', content: data['reply']));
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Error de conexión';
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  // Vera analiza automáticamente el partido sin mostrar burbuja de usuario.
  Future<void> greet(String? token, String matchContext) async {
    if (_sending || _messages.isNotEmpty) return;
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiClient(token: token).post('/api/chat', {
        'messages': [
          {'role': 'user', 'content': 'Analiza brevemente este partido.'}
        ],
        'match_context': matchContext,
      });
      _messages.add(ChatMessage(role: 'assistant', content: data['reply']));
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Error de conexión';
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  void clear() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }
}
