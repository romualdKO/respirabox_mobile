import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/services/gemini_ai_service.dart';
import '../../../data/services/assemblyai_service.dart';
import '../../../data/services/conversation_service.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/providers/conversation_provider.dart';
import '../../../core/providers/app_providers.dart';

/// 💬 ÉCRAN CHATBOT IA
/// Assistance médicale avec Gemini AI
class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final GeminiAIService _geminiService = GeminiAIService();
  final AssemblyAIService _assemblyAIService = AssemblyAIService();
  ConversationModel? _currentConversation;
  final ConversationService _conversationService = ConversationService();

  // 🎤 Enregistrement vocal avec flutter_sound
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _loadOrCreateConversation();
    _initAudioRecorder();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.closeRecorder();
    super.dispose();
  }

  /// Initialiser FlutterSoundRecorder
  Future<void> _initAudioRecorder() async {
    await _audioRecorder.openRecorder();
  }

  /// Charger la dernière conversation active ou en créer une nouvelle
  Future<void> _loadOrCreateConversation() async {
    try {
      final userAsync = ref.read(currentUserProvider);

      final user = await userAsync.when(
        data: (user) => user,
        loading: () => null,
        error: (_, __) => null,
      );

      if (user == null) {
        print('❌ Utilisateur non connecté');
        return;
      }

      print('📂 Chargement conversation pour user: ${user.id}');

      // Essayer de charger la dernière conversation active
      final activeConv =
          await _conversationService.getActiveConversation(user.id);

      if (activeConv != null && activeConv.messages.isNotEmpty) {
        // Charger les messages existants
        print(
            '✅ Conversation active trouvée: ${activeConv.id} avec ${activeConv.messages.length} messages');
        setState(() {
          _currentConversation = activeConv;
          _messages.clear();
          _messages.addAll(activeConv.messages.map((m) => ChatMessage(
                text: m.text,
                isUser: m.isUser,
                timestamp: m.timestamp,
              )));
        });
      } else {
        // Créer une nouvelle conversation
        print('➕ Aucune conversation active, création...');
        await _createNewConversation();
      }
    } catch (e) {
      print('❌ Erreur chargement conversation: $e');
    }
  }

  /// Créer une nouvelle conversation
  Future<void> _createNewConversation() async {
    try {
      final userAsync = ref.read(currentUserProvider);

      final user = await userAsync.when(
        data: (user) => user,
        loading: () => null,
        error: (_, __) => null,
      );

      if (user == null) {
        print('❌ Impossible de créer conversation: utilisateur non connecté');
        return;
      }

      // Désactiver toutes les conversations précédentes
      await _conversationService.deactivateAllConversations(user.id);

      // Créer une nouvelle conversation
      final newConv = await _conversationService.createConversation(
        userId: user.id,
        firstMessage: 'Nouvelle conversation',
      );

      print('✅ Conversation créée: ${newConv.id}');

      setState(() {
        _currentConversation = newConv;
        _messages.clear();
      });

      _addWelcomeMessage();
    } catch (e) {
      print('❌ Erreur création conversation: $e');
    }
  }

  /// Charger une conversation existante
  Future<void> _loadConversation(ConversationModel conversation) async {
    setState(() {
      _currentConversation = conversation;
      _messages.clear();
      _messages.addAll(conversation.messages.map((m) => ChatMessage(
            text: m.text,
            isUser: m.isUser,
            timestamp: m.timestamp,
          )));
    });
    Navigator.pop(context); // Fermer le drawer
  }

  void _addWelcomeMessage() {
    // Déterminer la salutation selon l'heure
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Bonjour';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Bon après-midi';
    } else {
      greeting = 'Bonsoir';
    }

    final welcomeMsg = ChatMessage(
      text: '🤖 $greeting ! Je suis votre assistant médical RespiraBox.\n\n'
          '💬 Parlez-moi de ce que vous voulez, je comprends TOUT !\n\n'
          '✨ Posez-moi n\'importe quelle question sur votre santé respiratoire, '
          'vos tests, vos symptômes... Je suis là pour vous aider !',
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(welcomeMsg);
    });

    // Sauvegarder dans la conversation
    if (_currentConversation != null) {
      _conversationService.addMessage(
        conversationId: _currentConversation!.id,
        text: welcomeMsg.text,
        isUser: false,
      );
    }
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

    // Sauvegarder le message utilisateur dans la conversation
    if (_currentConversation != null) {
      print(
          '💾 Sauvegarde message utilisateur dans conversation: ${_currentConversation!.id}');
      await _conversationService.addMessage(
        conversationId: _currentConversation!.id,
        text: userMessage.text,
        isUser: true,
      );
    } else {
      print('⚠️ Aucune conversation active pour sauvegarder le message');
    }

    try {
      // Récupérer l'utilisateur actuel
      final userAsync = ref.read(currentUserProvider);

      userAsync.when(
        data: (user) async {
          if (user == null) {
            setState(() {
              _messages.add(ChatMessage(
                text:
                    '❌ Veuillez vous connecter pour utiliser l\'assistant IA.',
                isUser: false,
                timestamp: DateTime.now(),
              ));
              _isTyping = false;
            });
            return;
          }

          // L'assistant médical répond intelligemment à tout
          // Elle analyse automatiquement l'intention de l'utilisateur
          String botResponse = await _geminiService.sendMessage(
            userMessage: text,
            userId: user.id,
          );

          final botMessage = ChatMessage(
            text: botResponse,
            isUser: false,
            timestamp: DateTime.now(),
          );

          setState(() {
            _messages.add(botMessage);
            _isTyping = false;
          });

          // Sauvegarder la réponse de l'IA dans la conversation
          if (_currentConversation != null) {
            print(
                '💾 Sauvegarde réponse IA dans conversation: ${_currentConversation!.id}');
            await _conversationService.addMessage(
              conversationId: _currentConversation!.id,
              text: botMessage.text,
              isUser: false,
            );
          } else {
            print(
                '⚠️ Aucune conversation active pour sauvegarder la réponse IA');
          }

          _scrollToBottom();
        },
        loading: () {
          setState(() {
            _messages.add(ChatMessage(
              text: '⏳ Chargement de votre profil...',
              isUser: false,
              timestamp: DateTime.now(),
            ));
            _isTyping = false;
          });
        },
        error: (error, stack) {
          setState(() {
            _messages.add(ChatMessage(
              text: '❌ Erreur: $error',
              isUser: false,
              timestamp: DateTime.now(),
            ));
            _isTyping = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: '❌ Une erreur s\'est produite: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    }

    _scrollToBottom();
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

  /// 🎤 Démarrer/Arrêter l'enregistrement vocal avec flutter_sound
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Arrêter l'enregistrement
      final path = await _audioRecorder.stopRecorder();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _recordingPath = path;
        });

        // Afficher dialogue: transcription ou analyse de toux
        _showAudioOptionsDialog(path);
      }
    } else {
      // Vérifier les permissions
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        // Démarrer l'enregistrement
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';

        await _audioRecorder.startRecorder(
          toFile: filePath,
          codec: Codec.aacADTS,
        );

        setState(() {
          _isRecording = true;
          _recordingPath = filePath;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.mic, color: Colors.white),
                SizedBox(width: 8),
                Text('🎤 Enregistrement en cours...'),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Permission microphone refusée'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 🎯 Afficher options après enregistrement
  void _showAudioOptionsDialog(String audioPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.audiotrack, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Audio enregistré'),
          ],
        ),
        content: const Text('Que voulez-vous faire avec cet audio ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _transcribeAndSend(audioPath);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline),
                SizedBox(width: 4),
                Text('Transcrire en texte'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _analyzeCoughAndSend(audioPath);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.healing),
                SizedBox(width: 4),
                Text('Analyser la toux'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Transcrire l'audio en texte et envoyer
  Future<void> _transcribeAndSend(String audioPath) async {
    setState(() {
      _isTyping = true;
      _messages.add(ChatMessage(
        text: '🎤 Transcription de votre message vocal...',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    try {
      final transcription =
          await _assemblyAIService.transcribeFromFile(audioPath);

      // Retirer le message de chargement
      setState(() {
        _messages.removeLast();
      });

      if (transcription.isNotEmpty) {
        // Envoyer le texte transcrit comme message
        await _sendMessage(transcription);
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: '❌ Aucune parole détectée dans l\'audio.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: '❌ Erreur de transcription: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    }
  }

  /// 🩺 Analyser la toux et envoyer à l'IA
  Future<void> _analyzeCoughAndSend(String audioPath) async {
    setState(() {
      _isTyping = true;
      _messages.add(ChatMessage(
        text: '🩺 Analyse de votre toux en cours...',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    try {
      final analysis = await _assemblyAIService.analyzeCough(audioPath);

      // Retirer le message de chargement
      setState(() {
        _messages.removeLast();
      });

      // Créer un message pour l'utilisateur
      final userMessage = '🎤 [Audio de toux envoyé pour analyse]';
      setState(() {
        _messages.add(ChatMessage(
          text: userMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ));
      });

      // Sauvegarder dans la conversation
      if (_currentConversation != null) {
        await _conversationService.addMessage(
          conversationId: _currentConversation!.id,
          text: userMessage,
          isUser: true,
        );
      }

      // Construire le contexte pour l'IA
      final analysisContext = '''
J'ai enregistré un audio de toux. Voici l'analyse:

- Toux détectée: ${analysis['hasCough'] ? 'OUI ✅' : 'NON ❌'}
- Nombre d'événements: ${analysis['coughCount']}
- Durée audio: ${analysis['duration']} secondes

Peux-tu analyser cette toux et me donner des conseils médicaux ?
''';

      // Envoyer à l'IA pour analyse approfondie
      final userAsync = ref.read(currentUserProvider);
      userAsync.when(
        data: (user) async {
          if (user != null) {
            final aiResponse = await _geminiService.sendMessage(
              userMessage: analysisContext,
              userId: user.id,
            );

            final botMessage = ChatMessage(
              text: aiResponse,
              isUser: false,
              timestamp: DateTime.now(),
            );

            setState(() {
              _messages.add(botMessage);
              _isTyping = false;
            });

            // Sauvegarder la réponse de l'IA
            if (_currentConversation != null) {
              await _conversationService.addMessage(
                conversationId: _currentConversation!.id,
                text: botMessage.text,
                isUser: false,
              );
            }

            _scrollToBottom();
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: '❌ Erreur d\'analyse: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) => Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.smart_toy, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assistant RespiraBox',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentConversation != null
                        ? _currentConversation!.title.length > 20
                            ? '${_currentConversation!.title.substring(0, 20)}...'
                            : _currentConversation!.title
                        : 'Nouvelle conversation',
                    style: const TextStyle(
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
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Nouvelle conversation',
              onPressed: _createNewConversation,
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () => _showInfoDialog(),
            ),
          ],
        ),
        drawer: user != null ? _buildHistoryDrawer(user.id) : null,
        body: Column(
          children: [
            // Avertissement médical
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.warning.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: AppColors.warning, size: 20),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text('Erreur: $error'),
        ),
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
              child: const Icon(Icons.smart_toy,
                  color: AppColors.primary, size: 20),
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
                    color: message.isUser ? AppColors.primary : Colors.white,
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
              child:
                  const Icon(Icons.person, color: AppColors.primary, size: 20),
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
          // 🎤 Bouton microphone pour enregistrement vocal
          Container(
            decoration: BoxDecoration(
              color: _isRecording ? AppColors.error : AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
              ),
              onPressed: _toggleRecording,
              tooltip: _isRecording
                  ? 'Arrêter l\'enregistrement'
                  : 'Enregistrer un message vocal',
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: _isRecording
                    ? '🎤 Enregistrement...'
                    : 'Posez votre question...',
                hintStyle: TextStyle(
                  color: _isRecording ? AppColors.error : AppColors.textLight,
                  fontWeight:
                      _isRecording ? FontWeight.bold : FontWeight.normal,
                ),
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
              enabled: !_isRecording,
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
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: AppColors.primary),
            const SizedBox(width: 10),
            const Text('Assistant IA Gemini'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🤖 Assistant médical RespiraBox',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                'Intelligence Artificielle Conversationnelle :',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('✅ Comprend le langage naturel humain'),
              Text('✅ Aucune commande spécifique requise'),
              Text('✅ Analyse intelligente de vos données'),
              Text('✅ Répond à TOUTES vos questions'),
              Text('✅ Détection automatique de l\'intention'),
              const SizedBox(height: 12),
              Text(
                '💬 Parlez librement, l\'IA comprend TOUT !',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Text(
                  '⚠️ Attention: Cet assistant ne remplace pas un diagnostic médical professionnel.',
                  style: TextStyle(fontSize: 12, color: AppColors.textDark),
                ),
              ),
            ],
          ),
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

  /// 📋 Drawer de l'historique des conversations
  Widget _buildHistoryDrawer(String userId) {
    final conversationsAsync = ref.watch(userConversationsProvider(userId));

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Historique des conversations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Bouton nouvelle conversation
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _createNewConversation,
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle conversation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // Liste des conversations
            Expanded(
              child: conversationsAsync.when(
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucune conversation',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      final isActive = conv.id == _currentConversation?.id;

                      return ListTile(
                        selected: isActive,
                        selectedTileColor: AppColors.primary.withOpacity(0.1),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.chat_bubble,
                            color: isActive ? Colors.white : Colors.grey,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          conv.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${conv.messages.length} messages • ${_formatDate(conv.updatedAt)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _deleteConversation(conv.id),
                        ),
                        onTap: () => _loadConversation(conv),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                  child: Text('Erreur de chargement'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formater la date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Supprimer une conversation
  Future<void> _deleteConversation(String conversationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la conversation ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _conversationService.deleteConversation(conversationId);

      // Si c'est la conversation actuelle, en créer une nouvelle
      if (_currentConversation?.id == conversationId) {
        await _createNewConversation();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Conversation supprimée')),
        );
      }
    }
  }
}

/// 💬 MODÈLE DE MESSAGE CHAT
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
