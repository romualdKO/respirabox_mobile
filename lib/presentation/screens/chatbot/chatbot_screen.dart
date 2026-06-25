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
import '../../../data/services/patient_context_service.dart';
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

  // 🆕 SÉPARATION: Transcription vs Analyse toux
  bool _isRecordingForTranscription = false; // Enregistrement pour parler
  bool _isRecordingForCough = false; // Enregistrement pour tousser

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

  /// Attend que l'auth soit résolue (max 5s) et retourne l'utilisateur
  Future<dynamic> _getUser() async {
    for (int i = 0; i < 10; i++) {
      final asyncUser = ref.read(currentUserProvider);
      if (asyncUser is AsyncData) return asyncUser.value;
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return null;
    }
    return null;
  }

  /// Charger la dernière conversation active ou en créer une nouvelle
  Future<void> _loadOrCreateConversation() async {
    try {
      final user = await _getUser();

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
      final user = await _getUser();

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
    try {
      print('📂 Chargement conversation: ${conversation.id}');

      final user = await _getUser();

      if (user == null) {
        print('❌ Impossible de charger: utilisateur non connecté');
        return;
      }

      // Désactiver toutes les autres conversations
      await _conversationService.deactivateAllConversations(user.id);
      
      // Activer cette conversation
      await _conversationService.activateConversation(conversation.id);
      
      setState(() {
        _currentConversation = conversation;
        _messages.clear();
        _messages.addAll(conversation.messages.map((m) => ChatMessage(
              text: m.text,
              isUser: m.isUser,
              timestamp: m.timestamp,
            )));
      });
      
      print('✅ Conversation chargée avec ${conversation.messages.length} messages');
      
      if (mounted) {
        Navigator.pop(context); // Fermer le drawer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Conversation "${conversation.title}" chargée'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur chargement conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

      // 🆕 Mettre à jour le titre si c'est le premier message utilisateur
      if (_currentConversation!.title == 'Nouvelle conversation' ||
          _currentConversation!.title.isEmpty) {
        // Générer un titre à partir du premier message
        final newTitle = text.length > 40 ? '${text.substring(0, 40)}...' : text;
        await _conversationService.updateConversationTitle(
          conversationId: _currentConversation!.id,
          title: newTitle,
        );
        print('✏️ Titre de conversation mis à jour: $newTitle');
        
        // Mettre à jour localement aussi
        _currentConversation = ConversationModel(
          id: _currentConversation!.id,
          userId: _currentConversation!.userId,
          title: newTitle,
          createdAt: _currentConversation!.createdAt,
          updatedAt: DateTime.now(),
          messages: _currentConversation!.messages,
          isActive: _currentConversation!.isActive,
        );
      }
    } else {
      print('⚠️ Aucune conversation active pour sauvegarder le message');
    }

    try {
      final user = await _getUser();

      if (user == null) {
        setState(() {
          _messages.add(ChatMessage(
            text: '❌ Veuillez vous connecter pour utiliser l\'assistant IA.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        return;
      }

      // Construire l'historique des 6 derniers échanges (hors message d'accueil)
      final recentMsgs = _messages
          .where((m) =>
              !m.text.startsWith('🤖 Bonjour') &&
              !m.text.startsWith('🤖 Bon après') &&
              !m.text.startsWith('🤖 Bonsoir'))
          .toList();
      const _kHistoryContextWindow = 6;
      final historySlice = recentMsgs.length > _kHistoryContextWindow
          ? recentMsgs.sublist(recentMsgs.length - _kHistoryContextWindow)
          : recentMsgs;
      final history = historySlice
          .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'text': m.text})
          .toList();

      final String botResponse = await _geminiService.sendMessage(
        userMessage: text,
        userId: user.id,
        history: history,
      );

      final botMessage = ChatMessage(
        text: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (!mounted) return;
      setState(() {
        _messages.add(botMessage);
        _isTyping = false;
      });

      if (_currentConversation != null) {
        await _conversationService.addMessage(
          conversationId: _currentConversation!.id,
          text: botMessage.text,
          isUser: false,
        );
      }

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
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

  /// 🎤 NOUVEAU: Enregistrement pour TRANSCRIPTION (bouton bleu)
  Future<void> _toggleVoiceRecording() async {
    if (_isRecordingForTranscription) {
      // Arrêter l'enregistrement et transcrire automatiquement
      final path = await _audioRecorder.stopRecorder();
      if (path != null) {
        setState(() {
          _isRecordingForTranscription = false;
          _isRecording = false;
        });

        // Transcrire directement sans dialogue
        _transcribeAndSend(path);
      }
    } else {
      // Vérifier les permissions
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        // Arrêter l'autre enregistrement si actif
        if (_isRecordingForCough) {
          await _audioRecorder.stopRecorder();
          setState(() {
            _isRecordingForCough = false;
          });
        }

        // Démarrer l'enregistrement
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

        await _audioRecorder.startRecorder(
          toFile: filePath,
          codec: Codec.aacADTS,
        );

        setState(() {
          _isRecordingForTranscription = true;
          _isRecording = true;
          _recordingPath = filePath;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.mic, color: Colors.white),
                SizedBox(width: 8),
                Text('🎤 Enregistrement vocal (transcription)...'),
              ],
            ),
            backgroundColor: Colors.blue,
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

  /// 🩺 NOUVEAU: Enregistrement pour ANALYSE TOUX (bouton rouge)
  /// Questionnaire clinique complet (WHO TB screen + PSI Pneumonie + épidémio)
  Future<Map<String, dynamic>?> _showSymptomQuestionnaire() async {
    int durationDays = 3;
    bool hasFever = false;
    bool hasNightSweats = false;
    bool hasWeightLoss = false;
    bool hasChestPain = false;
    bool hasDyspnea = false;
    bool tbContact = false;
    bool isImmunocompromised = false;

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Bilan clinique pré-analyse',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Durée toux
                const Text('Durée de la toux',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Row(children: [
                  Expanded(
                    child: Slider(
                      value: durationDays.toDouble(),
                      min: 1, max: 60, divisions: 59,
                      label: '$durationDays j',
                      activeColor: durationDays >= 14 ? Colors.red : Colors.blue,
                      onChanged: (v) => setDialogState(() => durationDays = v.round()),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: durationDays >= 21 ? Colors.red.shade100
                          : durationDays >= 14 ? Colors.orange.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$durationDays j',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: durationDays >= 21 ? Colors.red.shade800
                              : durationDays >= 14 ? Colors.orange.shade800
                              : Colors.green.shade800,
                        )),
                  ),
                ]),
                if (durationDays >= 14)
                  Text('  ⚠️ Toux chronique — critère TB (WHO)',
                      style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
                const Divider(height: 20),

                // Symptômes cliniques
                const Text('Symptômes présents',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                _symptomTile('Fièvre (>38°C)', hasFever,
                    (v) => setDialogState(() => hasFever = v)),
                _symptomTile('Sueurs nocturnes', hasNightSweats,
                    (v) => setDialogState(() => hasNightSweats = v)),
                _symptomTile('Perte de poids inexpliquée', hasWeightLoss,
                    (v) => setDialogState(() => hasWeightLoss = v)),
                _symptomTile('Douleur thoracique', hasChestPain,
                    (v) => setDialogState(() => hasChestPain = v)),
                _symptomTile('Essoufflement / dyspnée', hasDyspnea,
                    (v) => setDialogState(() => hasDyspnea = v)),
                const Divider(height: 20),

                // Facteurs de risque épidémiologiques
                const Text('Facteurs de risque',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                _symptomTile('Contact avec un cas de TB connu', tbContact,
                    (v) => setDialogState(() => tbContact = v)),
                _symptomTile('Immunodéprimé (VIH, chimio, corticoïdes)',
                    isImmunocompromised,
                    (v) => setDialogState(() => isImmunocompromised = v)),

                // Résumé WHO
                const SizedBox(height: 8),
                Builder(builder: (_) {
                  int whoCount = 0;
                  if (durationDays >= 2) whoCount++;
                  if (hasFever) whoCount++;
                  if (hasNightSweats) whoCount++;
                  if (hasWeightLoss) whoCount++;
                  if (whoCount == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: whoCount >= 2 ? Colors.red.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: whoCount >= 2 ? Colors.red : Colors.orange),
                    ),
                    child: Text(
                      'WHO TB screen : $whoCount/4 symptômes\n'
                      '${whoCount >= 2 ? "⚠️ Investigation TB recommandée" : "Surveillance conseillée"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: whoCount >= 2 ? Colors.red.shade800 : Colors.orange.shade800,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Passer'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.biotech, size: 16),
              onPressed: () => Navigator.pop(ctx, {
                'symptomDurationDays': durationDays,
                'hasFever': hasFever,
                'hasNightSweats': hasNightSweats,
                'hasWeightLoss': hasWeightLoss,
                'hasChestPain': hasChestPain,
                'hasDyspnea': hasDyspnea,
                'tbContact': tbContact,
                'isImmunocompromised': isImmunocompromised,
              }),
              label: const Text('Analyser'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _symptomTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Future<void> _toggleCoughRecording() async {
    if (_isRecordingForCough) {
      // Arrêter l'enregistrement
      final path = await _audioRecorder.stopRecorder();
      if (path != null) {
        setState(() {
          _isRecordingForCough = false;
          _isRecording = false;
        });

        // Questionnaire clinique avant analyse
        final symptoms = await _showSymptomQuestionnaire();
        _analyzeCoughAndSend(path, symptoms: symptoms);
      }
    } else {
      // Vérifier les permissions
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        // Arrêter l'autre enregistrement si actif
        if (_isRecordingForTranscription) {
          await _audioRecorder.stopRecorder();
          setState(() {
            _isRecordingForTranscription = false;
          });
        }

        // Enregistrer en PCM/WAV pour que l'extracteur acoustique puisse lire les samples
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/cough_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _audioRecorder.startRecorder(
          toFile: filePath,
          codec: Codec.pcm16WAV,
          sampleRate: 44100,
          numChannels: 1,
        );

        setState(() {
          _isRecordingForCough = true;
          _isRecording = true;
          _recordingPath = filePath;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.coronavirus_outlined, color: Colors.white),
                SizedBox(width: 8),
                Text('🩺 Enregistrement toux (analyse acoustique)...'),
              ],
            ),
            backgroundColor: Colors.red,
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
  Future<void> _analyzeCoughAndSend(String audioPath,
      {Map<String, dynamic>? symptoms}) async {
    setState(() {
      _isTyping = true;
      _messages.add(ChatMessage(
        text: '🩺 Analyse clinique en cours (acoustique + symptômes + vitales)...',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    try {
      // Contexte patient (vitales ESP32 + profil Firestore)
      Map<String, dynamic> patientContext =
          await _buildPatientContext() ?? {};

      // Fusionner les symptômes déclarés par le patient
      if (symptoms != null) {
        patientContext.addAll(symptoms);
      }

      // 🎵 ANALYSE COMPLÈTE : acoustique + symptômes + vitales
      final analysis = await _assemblyAIService.analyzeCough(
        audioPath,
        patientContext: patientContext.isEmpty ? null : patientContext,
      );

      // Retirer le message de chargement
      setState(() {
        _messages.removeLast();
      });

      // 📊 NAVIGUER VERS ÉCRAN RÉSULTATS DÉTAILLÉS
      if (analysis['hasCough'] == true) {
        // Message utilisateur
        setState(() {
          _messages.add(ChatMessage(
            text: '🎤 [Analyse de toux effectuée]',
            isUser: true,
            timestamp: DateTime.now(),
          ));
        });

        // Message bot avec lien vers résultats
        final tbRisk = analysis['tbRisk'] ?? 0;
        final pneumoniaRisk = analysis['pneumoniaRisk'] ?? 0;
        final urgency = analysis['urgencyLevel'] ?? 'low';

        setState(() {
          _messages.add(ChatMessage(
            text: '''
✅ Analyse terminée avec succès!

📊 Résultats rapides:
• Type: ${analysis['type']}
• Risque TB: $tbRisk/100
• Risque Pneumonie: $pneumoniaRisk/100
• Urgence: ${urgency.toUpperCase()}

Appuyez sur le bouton ci-dessous pour voir l'analyse complète avec graphique comparatif.
''',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });

        // Naviguer vers écran résultats après court délai
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushNamed(
            context,
            '/cough-analysis-results',
            arguments: analysis,
          );
        });
      } else {
        // Audio trop court ou énergie insuffisante
        setState(() {
          _messages.add(ChatMessage(
            text: '🎤 [Audio envoyé pour analyse]',
            isUser: true,
            timestamp: DateTime.now(),
          ));

          // Expliquer POURQUOI la toux n'a pas été détectée
          final duration = analysis['duration'] ?? 0.0;
          final energy = analysis['acousticFeatures']?['energy'] ?? 0.0;

          String reason = '';
          if (duration < 1.0) {
            reason =
                '⏱️ Audio trop court (${duration.toStringAsFixed(1)}s). Enregistrez au moins 1 seconde.';
          } else if (energy < 0.3) {
            reason =
                '🔇 Énergie sonore insuffisante (${(energy * 100).toStringAsFixed(0)}%). Toussez plus fort près du micro.';
          } else {
            reason = '🎯 Aucune toux détectée dans le signal audio.';
          }

          _messages.add(ChatMessage(
            text: '''❌ Toux non détectée

$reason

💡 Conseils:
• Toussez clairement pendant 2-3 secondes
• Rapprochez-vous du microphone
• Évitez les bruits de fond
• Toussez naturellement (pas besoin de parler)''',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
      }

      _scrollToBottom();
    } catch (e) {
      print('❌ Erreur analyse toux: $e');
      setState(() {
        if (_messages.isNotEmpty && _messages.last.text.contains('Analyse')) {
          _messages.removeLast();
        }
        _messages.add(ChatMessage(
          text: '❌ Erreur lors de l\'analyse de la toux: $e\n\n'
              'Veuillez réessayer ou enregistrer un nouvel audio.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  /// 🔍 CONSTRUIRE CONTEXTE PATIENT COMPLET
  ///
  /// Combine:
  /// - Profil utilisateur (si disponible)
  /// - Mesures vitales récentes du test ESP32
  Future<Map<String, dynamic>?> _buildPatientContext() async {
    try {
      final context = await PatientContextService.buildPatientContext();

      if (context.isEmpty) {
        print('⚠️ Aucun contexte patient disponible');
        return null;
      }

      // Afficher message informatif sur les données utilisées
      if (context.containsKey('spo2')) {
        final vitalsAge = context['vitalsAge'] as int?;
        setState(() {
          _messages.add(ChatMessage(
            text:
                'ℹ️ Utilisation de vos mesures récentes (il y a $vitalsAge min):\n'
                '  • SpO2: ${context['spo2']}%\n'
                '  • Température: ${context['temperature']}°C\n'
                '  • Fréquence cardiaque: ${context['heartRate']} bpm',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }

      return context;
    } catch (e) {
      print('❌ Erreur construction contexte patient: $e');
      return null;
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
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final delay = index * 0.33;
        final phase = ((value - delay).clamp(0.0, 1.0));
        final bounce = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
        return Transform.translate(
          offset: Offset(0, -6 * bounce),
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.4 + bounce * 0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted && _isTyping) setState(() {});
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
          // 🎤 NOUVEAU: Bouton microphone VOCAL (transcription) - BLEU
          Container(
            decoration: BoxDecoration(
              color: _isRecordingForTranscription
                  ? Colors.red
                  : Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isRecordingForTranscription ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _toggleVoiceRecording,
              tooltip: _isRecordingForTranscription
                  ? 'Arrêter transcription'
                  : 'Message vocal (texte)',
            ),
          ),
          const SizedBox(width: 6),

          // 🩺 NOUVEAU: Bouton ANALYSE TOUX - ROUGE
          Container(
            decoration: BoxDecoration(
              color: _isRecordingForCough
                  ? Colors.red.shade900
                  : Colors.red.shade600,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isRecordingForCough ? Icons.stop : Icons.coronavirus_outlined,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _toggleCoughRecording,
              tooltip: _isRecordingForCough
                  ? 'Arrêter analyse'
                  : 'Analyser ma toux',
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: _isRecording
                    ? (_isRecordingForTranscription
                        ? '🎤 Enregistrement vocal...'
                        : '🩺 Enregistrement toux...')
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

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: isActive
                              ? Border.all(
                                  color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: ListTile(
                          selected: isActive,
                          selectedTileColor:
                              AppColors.primary.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: Stack(
                            children: [
                              Container(
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
                              if (isActive)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conv.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${conv.messages.length} messages • ${_formatDate(conv.updatedAt)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: isActive
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20, color: Colors.red),
                                  onPressed: () =>
                                      _deleteConversation(conv.id),
                                ),
                          onTap: isActive ? null : () => _loadConversation(conv),
                        ),
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
