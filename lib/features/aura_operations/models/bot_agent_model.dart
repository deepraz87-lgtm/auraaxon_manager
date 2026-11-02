enum BotStatus {
  idle,
  running,
  blocked,
  offline,
}

class BotAgent {
  final String id;
  final String name;
  final String role;
  final String description;
  final BotStatus status;
  final String? currentTask;
  final String engine;
  final DateTime lastActive;

  const BotAgent({
    required this.id,
    required this.name,
    required this.role,
    required this.description,
    required this.status,
    this.currentTask,
    required this.engine,
    required this.lastActive,
  });

  BotAgent copyWith({
    String? id,
    String? name,
    String? role,
    String? description,
    BotStatus? status,
    String? currentTask,
    String? engine,
    DateTime? lastActive,
  }) {
    return BotAgent(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      description: description ?? this.description,
      status: status ?? this.status,
      currentTask: currentTask ?? this.currentTask,
      engine: engine ?? this.engine,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  factory BotAgent.fromJson(Map<String, dynamic> json) {
    return BotAgent(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'Specialist',
      description: json['description'] as String? ?? '',
      status: _statusFromString(json['status'] as String? ?? 'idle'),
      currentTask: json['current_task'] as String?,
      engine: json['engine'] as String? ?? 'Antigravity',
      lastActive: json['last_active'] != null
          ? DateTime.tryParse(json['last_active'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'description': description,
      'status': status.name,
      'current_task': currentTask,
      'engine': engine,
      'last_active': lastActive.toIso8601String(),
    };
  }

  static BotStatus _statusFromString(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'running':
      case 'busy':
        return BotStatus.running;
      case 'blocked':
      case 'waiting_for_input':
      case 'errored':
        return BotStatus.blocked;
      case 'offline':
        return BotStatus.offline;
      default:
        return BotStatus.idle;
    }
  }
}

enum TaskStatus {
  queued,
  inProgress,
  completed,
  failed,
  needsInput,
}

class BotTask {
  final String id;
  final String targetBotId;
  final String targetBotName;
  final String brief;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? resultSummary;

  const BotTask({
    required this.id,
    required this.targetBotId,
    required this.targetBotName,
    required this.brief,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.resultSummary,
  });

  BotTask copyWith({
    String? id,
    String? targetBotId,
    String? targetBotName,
    String? brief,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? resultSummary,
  }) {
    return BotTask(
      id: id ?? this.id,
      targetBotId: targetBotId ?? this.targetBotId,
      targetBotName: targetBotName ?? this.targetBotName,
      brief: brief ?? this.brief,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      resultSummary: resultSummary ?? this.resultSummary,
    );
  }

  factory BotTask.fromJson(Map<String, dynamic> json) {
    return BotTask(
      id: json['id'] as String,
      targetBotId: json['target_bot_id'] as String,
      targetBotName: json['target_bot_name'] as String? ?? 'Bot',
      brief: json['brief'] as String,
      status: _taskStatusFromString(json['status'] as String? ?? 'queued'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      resultSummary: json['result_summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'target_bot_id': targetBotId,
      'target_bot_name': targetBotName,
      'brief': brief,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'result_summary': resultSummary,
    };
  }

  static TaskStatus _taskStatusFromString(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'inprogress':
      case 'in_progress':
      case 'running':
        return TaskStatus.inProgress;
      case 'completed':
      case 'done':
        return TaskStatus.completed;
      case 'failed':
        return TaskStatus.failed;
      case 'needsinput':
      case 'needs_input':
      case 'blocked':
        return TaskStatus.needsInput;
      default:
        return TaskStatus.queued;
    }
  }
}

class BotIncident {
  final String id;
  final String botId;
  final String botName;
  final String reason;
  final String? threadId;
  final DateTime createdAt;
  final bool resolved;

  const BotIncident({
    required this.id,
    required this.botId,
    required this.botName,
    required this.reason,
    this.threadId,
    required this.createdAt,
    this.resolved = false,
  });

  factory BotIncident.fromJson(Map<String, dynamic> json) {
    return BotIncident(
      id: json['id'] as String,
      botId: json['bot_id'] as String,
      botName: json['bot_name'] as String? ?? 'Agent',
      reason: json['reason'] as String,
      threadId: json['thread_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      resolved: json['resolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bot_id': botId,
      'bot_name': botName,
      'reason': reason,
      'thread_id': threadId,
      'created_at': createdAt.toIso8601String(),
      'resolved': resolved,
    };
  }
}
