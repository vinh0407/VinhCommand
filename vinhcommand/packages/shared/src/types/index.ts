export interface User {
  id: string;
  username: string;
  email: string;
  avatarUrl?: string;
  createdAt: Date;
}

export interface Project {
  id: string;
  name: string;
  path: string;
  description?: string;
  language: string;
  framework?: string;
  lastOpenedAt: Date;
  createdAt: Date;
}

export interface FileNode {
  id: string;
  name: string;
  path: string;
  type: 'file' | 'directory';
  children?: FileNode[];
  size?: number;
  modifiedAt: Date;
  isExpanded?: boolean;
  isSelected?: boolean;
}

export interface TerminalSession {
  id: string;
  name: string;
  cwd: string;
  shell: string;
  cols: number;
  rows: number;
  createdAt: Date;
  isActive: boolean;
}

export interface TerminalOutput {
  sessionId: string;
  data: string;
  type: 'stdout' | 'stderr' | 'system';
  timestamp: Date;
}

export interface EditorTab {
  id: string;
  filePath: string;
  fileName: string;
  language: string;
  content: string;
  isDirty: boolean;
  cursorPosition?: { line: number; column: number };
  scrollPosition?: { top: number; left: number };
}

export interface AIMessage {
  id: string;
  role: 'user' | 'assistant' | 'system' | 'tool';
  content: string;
  timestamp: Date;
  toolCalls?: ToolCall[];
  toolCallId?: string;
}

export interface ToolCall {
  id: string;
  name: string;
  arguments: Record<string, unknown>;
}

export interface AIAgent {
  id: string;
  name: string;
  type: 'codex' | 'antigravity' | 'custom';
  status: 'idle' | 'running' | 'waiting' | 'error';
  currentProjectId?: string;
  config: Record<string, unknown>;
}

export interface Workspace {
  id: string;
  name: string;
  projects: Project[];
  activeProjectId?: string;
  settings: WorkspaceSettings;
}

export interface WorkspaceSettings {
  theme: 'light' | 'dark' | 'system';
  fontSize: number;
  fontFamily: string;
  tabSize: number;
  wordWrap: boolean;
  minimap: boolean;
  autoSave: boolean;
  terminalShell: string;
  aiProvider: 'codex' | 'antigravity' | 'openai' | 'anthropic';
}

export interface GitStatus {
  branch: string;
  ahead: number;
  behind: number;
  staged: string[];
  unstaged: string[];
  untracked: string[];
  conflicted: string[];
}

export interface GitCommit {
  hash: string;
  shortHash: string;
  message: string;
  author: string;
  email: string;
  date: Date;
  files: GitFileChange[];
}

export interface GitFileChange {
  path: string;
  status: 'added' | 'modified' | 'deleted' | 'renamed' | 'copied';
  additions: number;
  deletions: number;
}

export interface SearchResult {
  filePath: string;
  lineNumber: number;
  column: number;
  match: string;
  context: string;
}

export interface Notification {
  id: string;
  type: 'info' | 'success' | 'warning' | 'error';
  title: string;
  message: string;
  action?: { label: string; onClick: () => void };
  duration?: number;
}

export interface KeyboardShortcut {
  id: string;
  key: string;
  modifiers: ('ctrl' | 'shift' | 'alt' | 'meta')[];
  action: string;
  description: string;
  when?: string;
}