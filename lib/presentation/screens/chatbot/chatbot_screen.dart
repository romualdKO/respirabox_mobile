import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

/// 💬 ÉCRAN CHATBOT IA
/// Assistance médicale avec Gemini AI
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: 'Bonjour ! Je suis votre assistant virtuel RespiraBox. Je peux vous aider avec :\n\n'
            '• Interprétation de vos résultats de tests\n'
            '• Conseils sur la santé respiratoire\n'
            '• Réponses à vos questions médicales\n'
            '• Orientation vers des professionnels de santé\n\n'
            'Comment puis-je vous aider aujourd\'hui ?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simuler une réponse de l'IA (en attendant l'intégration Gemini)
    await Future.delayed(const Duration(seconds: 2));

    final botResponse = _generateMockResponse(text);

    setState(() {
      _messages.add(ChatMessage(
        text: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isTyping = false;
    });

    _scrollToBottom();
  }

  String _generateMockResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('spo2') || message.contains('oxygène')) {
      return 'La saturation en oxygène (SpO2) normale se situe entre 95% et 100%. '
          'Si votre SpO2 est inférieure à 95%, cela peut indiquer une hypoxémie. '
          'Consultez un médecin si vos niveaux sont constamment bas ou si vous avez des difficultés respiratoires.';
    }

    if (message.contains('résultat') || message.contains('test')) {
      return 'Pour interpréter vos résultats de test :\n\n'
          '• SpO2 > 95% : Normal ✓\n'
          '• FC 60-100 bpm : Normal ✓\n'
          '• Température 36-37.5°C : Normal ✓\n\n'
          'Si vous avez des résultats préoccupants, je vous recommande de consulter un professionnel de santé.';
    }

    if (message.contains('toux') || message.contains('symptôme')) {
      return 'Les symptômes respiratoires courants incluent :\n\n'
          '• Toux persistante\n'
          '• Essoufflement\n'
          '• Respiration sifflante\n'
          '• Douleur thoracique\n\n'
          'Si vos symptômes persistent ou s\'aggravent, consultez rapidement un médecin.';
    }

    if (message.contains('covid') || message.contains('coronavirus')) {
      return 'Pour la COVID-19, surveillez ces signes :\n\n'
          '• Fièvre ou frissons\n'
          '• Toux sèche\n'
          '• Fatigue importante\n'
          '• Perte du goût/odorat\n'
          '• Difficulté respiratoire\n\n'
          'En cas de symptômes graves (essoufflement, douleur thoracique), contactez immédiatement les urgences.';
    }

    if (message.contains('médecin') || message.contains('docteur') || message.contains('consultation')) {
      return 'Vous devriez consulter un médecin si :\n\n'
          '• Vos symptômes persistent plus de 7 jours\n'
          '• Vous avez des difficultés respiratoires\n'
          '• Votre SpO2 est inférieure à 92%\n'
          '• Vous avez de la fièvre élevée persistante\n'
          '• Vous ressentez une douleur thoracique\n\n'
          'Je peux vous aider à trouver un professionnel de santé près de chez vous.';
    }

    if (message.contains('merci') || message.contains('remerci')) {
      return 'Je vous en prie ! N\'hésitez pas si vous avez d\'autres questions. '
          'Votre santé est importante. 😊';
    }

    // Réponse par défaut
    return 'Je comprends votre question. Pour vous donner des conseils personnalisés, '
        'pouvez-vous me donner plus de détails ?\n\n'
        'Vous pouvez me poser des questions sur :\n'
        '• Vos résultats de tests\n'
        '• Vos symptômes respiratoires\n'
        '• Les maladies respiratoires\n'
        '• Quand consulter un médecin';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistant RespiraBox',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'En ligne',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Avertissement médical
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.warning.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cet assistant ne remplace pas un avis médical professionnel',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Indicateur de frappe
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingDot(0),
                        const SizedBox(width: 4),
                        _buildTypingDot(1),
                        const SizedBox(width: 4),
                        _buildTypingDot(2),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Zone de saisie
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? AppColors.primary
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : AppColors.textDark,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.primary, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = ((value - delay).clamp(0.0, 1.0));
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.3 + (animValue * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted && _isTyping) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Posez votre question...',
                hintStyle: TextStyle(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos de l\'assistant'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'L\'assistant virtuel RespiraBox utilise l\'intelligence artificielle pour vous fournir des informations sur la santé respiratoire.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '⚠️ Important',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Cet assistant ne remplace pas un diagnostic médical professionnel. En cas de symptômes graves, consultez immédiatement un médecin.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}

/// Modèle de message
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
