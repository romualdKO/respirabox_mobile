/// 💬 MODÈLE DE CONVERSATION
/// Représente une conversation dans le chatbot
class ConversationModel {
  final String id;
  final String userId;
  final String title; // Titre généré automatiquement
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MessageModel> messages;
  final bool isActive; // Conversation en cours

  ConversationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.isActive = true,
  });

  /// Conversion depuis JSON
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      messages: (json['messages'] as List?)
              ?.map((m) => MessageModel.fromJson(m))
              .toList() ??
          [],
      isActive: json['isActive'] ?? true,
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'isActive': isActive,
    };
  }

  /// Conversion depuis Firestore
  factory ConversationModel.fromFirestore(dynamic doc) {
    final Map<String, dynamic> data = doc.data() ?? {};
    return ConversationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
      messages: (data['messages'] as List?)
              ?.map((m) => MessageModel.fromJson(m))
              .toList() ??
          [],
      isActive: data['isActive'] ?? true,
    );
  }

  /// Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'isActive': isActive,
    };
  }

  /// Copie avec modification
  ConversationModel copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MessageModel>? messages,
    bool? isActive,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Dernier message de la conversation
  MessageModel? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Aperçu du dernier message (50 premiers caractères)
  String get lastMessagePreview {
    if (messages.isEmpty) return 'Aucun message';
    final text = messages.last.text;
    return text.length > 50 ? '${text.substring(0, 50)}...' : text;
  }
}

/// 📝 MODÈLE DE MESSAGE
/// Représente un message dans une conversation
class MessageModel {
  final String text;
  final bool isUser; // true = utilisateur, false = IA
  final DateTime timestamp;

  MessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  /// Conversion depuis JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
