class ChatMessage {
  final String id;
  final String message;
  final bool isUser; // true = user, false = AI
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata; // For charts, suggestions, etc.

  ChatMessage({
    required this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      message: json['message'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values[json['type'] ?? 0],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'metadata': metadata,
    };
  }
}

enum MessageType {
  text,
  chart,
  suggestion,
  warning,
  insight,
}