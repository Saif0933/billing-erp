class NotificationModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  final String channel;
  final String? referenceType;
  final String? referenceId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isRead,
    this.type = 'SYSTEM_ALERT',
    this.channel = 'IN_APP',
    this.referenceType,
    this.referenceId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['sentAt'] ?? json['createdAt'] ?? json['timestamp'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: (json['message'] ?? json['description'])?.toString() ?? '',
      timestamp: parsedDate,
      isRead: json['isRead'] == true || json['isRead'] == 1,
      type: json['type']?.toString() ?? 'SYSTEM_ALERT',
      channel: json['channel']?.toString() ?? 'IN_APP',
      referenceType: json['referenceType']?.toString(),
      referenceId: json['referenceId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': description,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type,
      'channel': channel,
      'referenceType': referenceType,
      'referenceId': referenceId,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    String? channel,
    String? referenceType,
    String? referenceId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      channel: channel ?? this.channel,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
    );
  }
}
