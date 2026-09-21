enum TaskState {
  queued,
  starting,
  running,
  waitingForInput,
  waitingForApproval,
  completed,
  failed,
  stopped,
  cancelled,
}

extension TaskStateExtension on TaskState {
  String get label {
    switch (this) {
      case TaskState.queued:
        return 'QUEUED';
      case TaskState.starting:
        return 'STARTING';
      case TaskState.running:
        return 'RUNNING';
      case TaskState.waitingForInput:
        return 'WAITING FOR INPUT';
      case TaskState.waitingForApproval:
        return 'WAITING FOR APPROVAL';
      case TaskState.completed:
        return 'COMPLETED';
      case TaskState.failed:
        return 'FAILED';
      case TaskState.stopped:
        return 'STOPPED';
      case TaskState.cancelled:
        return 'CANCELLED';
    }
  }

  bool get isTerminal {
    return this == TaskState.completed ||
        this == TaskState.failed ||
        this == TaskState.stopped ||
        this == TaskState.cancelled;
  }

  bool get isActive {
    return this == TaskState.starting ||
        this == TaskState.running ||
        this == TaskState.waitingForInput ||
        this == TaskState.waitingForApproval;
  }

  bool get canStop {
    return isActive;
  }

  bool get canRetry {
    return this == TaskState.failed || this == TaskState.stopped || this == TaskState.cancelled;
  }
}