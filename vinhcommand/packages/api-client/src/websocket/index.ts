import type { WebSocketMessage, WebSocketEventType, WebSocketEventPayload, TerminalOutputPayload, TerminalExitPayload, FileChangedPayload, GitStatusPayload, AIMessagePayload, AIStatusPayload, NotificationPayload } from '@vinhcommand/shared';

export interface WebSocketClientConfig {
  url: string;
  reconnect?: boolean;
  reconnectInterval?: number;
  maxReconnectAttempts?: number;
  onOpen?: () => void;
  onClose?: (event: CloseEvent) => void;
  onError?: (error: Event) => void;
}

type EventHandler<T> = (payload: T) => void;

export class WebSocketClient {
  private ws: WebSocket | null = null;
  private config: Required<WebSocketClientConfig>;
  private reconnectAttempts = 0;
  private reconnectTimer?: ReturnType<typeof setTimeout>;
  private eventHandlers: Map<string, Set<EventHandler<unknown>>> = new Map();
  private messageQueue: WebSocketMessage[] = [];
  private isConnecting = false;

  constructor(config: WebSocketClientConfig) {
    this.config = {
      url: config.url,
      reconnect: config.reconnect ?? true,
      reconnectInterval: config.reconnectInterval ?? 3000,
      maxReconnectAttempts: config.maxReconnectAttempts ?? 10,
      onOpen: config.onOpen ?? (() => {}),
      onClose: config.onClose ?? (() => {}),
      onError: config.onError ?? (() => {}),
    };
  }

  connect(): Promise<void> {
    if (this.ws?.readyState === WebSocket.OPEN || this.isConnecting) {
      return Promise.resolve();
    }

    this.isConnecting = true;

    return new Promise((resolve, reject) => {
      try {
        this.ws = new WebSocket(this.config.url);

        this.ws.onopen = () => {
          this.isConnecting = false;
          this.reconnectAttempts = 0;
          this.config.onOpen();
          this.flushQueue();
          resolve();
        };

        this.ws.onclose = (event) => {
          this.isConnecting = false;
          this.config.onClose(event);
          if (this.config.reconnect && this.reconnectAttempts < this.config.maxReconnectAttempts) {
            this.scheduleReconnect();
          }
        };

        this.ws.onerror = (error) => {
          this.config.onError(error);
          if (this.ws?.readyState !== WebSocket.OPEN) {
            this.isConnecting = false;
            reject(error);
          }
        };

        this.ws.onmessage = (event) => {
          this.handleMessage(event.data);
        };
      } catch (error) {
        this.isConnecting = false;
        reject(error);
      }
    });
  }

  disconnect() {
    this.config.reconnect = false;
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
    }
    if (this.ws) {
      this.ws.close(1000, 'Client disconnect');
      this.ws = null;
    }
  }

  send<T>(type: string, payload: T, id?: string): void {
    const message: WebSocketMessage<T> = {
      type,
      payload,
      id: id || `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
      timestamp: new Date().toISOString(),
    };

    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(message));
    } else {
      this.messageQueue.push(message);
    }
  }

  on<T extends WebSocketEventType>(eventType: T, handler: EventHandler<WebSocketEventPayload<T>>): () => void {
    const key = eventType;
    if (!this.eventHandlers.has(key)) {
      this.eventHandlers.set(key, new Set());
    }
    this.eventHandlers.get(key)!.add(handler as EventHandler<unknown>);

    return () => this.off(eventType, handler);
  }

  off<T extends WebSocketEventType>(eventType: T, handler: EventHandler<WebSocketEventPayload<T>>): void {
    const key = eventType;
    this.eventHandlers.get(key)?.delete(handler as EventHandler<unknown>);
  }

  private handleMessage(data: string) {
    try {
      const message: WebSocketMessage = JSON.parse(data);
      const handlers = this.eventHandlers.get(message.type);
      if (handlers) {
        handlers.forEach((handler) => {
          try {
            handler(message.payload);
          } catch (error) {
            console.error(`Error in WebSocket handler for ${message.type}:`, error);
          }
        });
      }
    } catch (error) {
      console.error('Failed to parse WebSocket message:', error);
    }
  }

  private flushQueue() {
    while (this.messageQueue.length > 0 && this.ws?.readyState === WebSocket.OPEN) {
      const message = this.messageQueue.shift()!;
      this.ws.send(JSON.stringify(message));
    }
  }

  private scheduleReconnect() {
    this.reconnectAttempts++;
    const delay = this.config.reconnectInterval * Math.min(this.reconnectAttempts, 5);
    this.reconnectTimer = setTimeout(() => {
      this.connect().catch(() => {});
    }, delay);
  }

  get readyState(): number {
    return this.ws?.readyState ?? WebSocket.CLOSED;
  }

  get isConnected(): boolean {
    return this.ws?.readyState === WebSocket.OPEN;
  }
}

// Convenience methods for common events
export function createWebSocketClient(config: WebSocketClientConfig): WebSocketClient & {
  onTerminalOutput: (handler: EventHandler<TerminalOutputPayload>) => () => void;
  onTerminalExit: (handler: EventHandler<TerminalExitPayload>) => () => void;
  onFileChanged: (handler: EventHandler<FileChangedPayload>) => () => void;
  onGitStatus: (handler: EventHandler<GitStatusPayload>) => () => void;
  onAIMessage: (handler: EventHandler<AIMessagePayload>) => () => void;
  onAIStatus: (handler: EventHandler<AIStatusPayload>) => () => void;
  onNotification: (handler: EventHandler<NotificationPayload>) => () => void;
} {
  const client = new WebSocketClient(config);

  return {
    ...client,
    onTerminalOutput: (handler) => client.on('terminal:output', handler),
    onTerminalExit: (handler) => client.on('terminal:exit', handler),
    onFileChanged: (handler) => client.on('file:changed', handler),
    onGitStatus: (handler) => client.on('git:status', handler),
    onAIMessage: (handler) => client.on('ai:message', handler),
    onAIStatus: (handler) => client.on('ai:status', handler),
    onNotification: (handler) => client.on('notification', handler),
  };
}