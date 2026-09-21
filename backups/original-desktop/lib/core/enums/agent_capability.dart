enum AgentCapability {
  prompt,
  streaming,
  input,
  stop,
  pause,
  resume,
  projectContext,
  terminal,
  fileEditing,
  gui,
  screen,
}

extension AgentCapabilityExtension on AgentCapability {
  String get label {
    switch (this) {
      case AgentCapability.prompt:
        return 'Prompt';
      case AgentCapability.streaming:
        return 'Streaming';
      case AgentCapability.input:
        return 'Input';
      case AgentCapability.stop:
        return 'Stop';
      case AgentCapability.pause:
        return 'Pause';
      case AgentCapability.resume:
        return 'Resume';
      case AgentCapability.projectContext:
        return 'Project Context';
      case AgentCapability.terminal:
        return 'Terminal';
      case AgentCapability.fileEditing:
        return 'File Editing';
      case AgentCapability.gui:
        return 'GUI';
      case AgentCapability.screen:
        return 'Screen';
    }
  }
}