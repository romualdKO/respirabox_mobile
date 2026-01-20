import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation_model.dart';
import '../services/conversation_service.dart';

/// 📦 PROVIDER DU SERVICE DE CONVERSATION
final conversationServiceProvider = Provider<ConversationService>((ref) {
  return ConversationService();
});

/// 📦 PROVIDER DE LA CONVERSATION ACTIVE
final activeConversationProvider =
    StateProvider<ConversationModel?>((ref) => null);

/// 📦 PROVIDER DES CONVERSATIONS DE L'UTILISATEUR
final userConversationsProvider =
    StreamProvider.family<List<ConversationModel>, String>(
  (ref, userId) {
    final service = ref.watch(conversationServiceProvider);
    return service.watchUserConversations(userId);
  },
);

/// 📦 PROVIDER D'UNE CONVERSATION SPÉCIFIQUE
final conversationProvider = StreamProvider.family<ConversationModel?, String>(
  (ref, conversationId) {
    final service = ref.watch(conversationServiceProvider);
    return service.watchConversation(conversationId);
  },
);
