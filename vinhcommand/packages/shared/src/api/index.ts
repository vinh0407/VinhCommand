export interface APIResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: APIError;
  meta?: ResponseMeta;
}

export interface APIError {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}

export interface ResponseMeta {
  timestamp: string;
  requestId: string;
  version: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

export interface WebSocketMessage<T = unknown> {
  type: string;
  payload: T;
  id?: string;
  timestamp: string;
}

export interface WebSocketEventMap {
  'terminal:output': TerminalOutputPayload;
  'terminal:exit': TerminalExitPayload;
  'file:changed': FileChangedPayload;
  'git:status': GitStatusPayload;
  'ai:message': AIMessagePayload;
  'ai:status': AIStatusPayload;
  'notification': NotificationPayload;
}

export interface TerminalOutputPayload {
  sessionId: string;
  data: string;
  type: 'stdout' | 'stderr';
}

export interface TerminalExitPayload {
  sessionId: string;
  exitCode: number;
}

export interface FileChangedPayload {
  path: string;
  type: 'created' | 'modified' | 'deleted' | 'renamed';
  oldPath?: string;
}

export interface GitStatusPayload {
  projectId: string;
  status: GitStatus;
}

export interface AIMessagePayload {
  agentId: string;
  message: AIMessage;
}

export interface AIStatusPayload {
  agentId: string;
  status: 'idle' | 'running' | 'waiting' | 'error';
}

export interface NotificationPayload {
  notification: Notification;
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

export interface AIMessage {
  id: string;
  role: 'user' | 'assistant' | 'system' | 'tool';
  content: string;
  timestamp: string;
  toolCalls?: ToolCall[];
  toolCallId?: string;
}

export interface ToolCall {
  id: string;
  name: string;
  arguments: Record<string, unknown>;
}

export interface Notification {
  id: string;
  type: 'info' | 'success' | 'warning' | 'error';
  title: string;
  message: string;
  action?: { label: string; handler: string };
  duration?: number;
}

export type WebSocketEventType = keyof WebSocketEventMap;
export type WebSocketEventPayload<T extends WebSocketEventType> = WebSocketEventMap[T];