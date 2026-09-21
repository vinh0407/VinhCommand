import { useEffect, useRef, useState } from 'react';
import { Send, Bot, Sparkles, Loader2, X, Copy, Check } from 'lucide-react';
import { Button, Input, Card, CardHeader, CardTitle, CardContent } from '@vinhcommand/ui-core';
import { RESTClient, createWebSocketClient } from '@vinhcommand/api-client';
import { AIMessage, AIAgent } from '@vinhcommand/shared';

const apiClient = new RESTClient({ baseUrl: 'http://localhost:3000' });

export function AIView() {
  const [agents, setAgents] = useState<AIAgent[]>([]);
  const [activeAgentId, setActiveAgentId] = useState<string | null>(null);
  const [messages, setMessages] = useState<AIMessage[]>([]);
  const [input, setInput] = useState('');
  const [sending, setSending] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const wsRef = useRef<ReturnType<typeof createWebSocketClient> | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    loadAgents();
    return () => wsRef.current?.disconnect();
  }, []);

  const loadAgents = async () => {
    try {
      const response = await apiClient.getAIAgents();
      if (response.success && response.data) {
        setAgents(response.data);
        if (response.data.length > 0 && !activeAgentId) {
          setActiveAgentId(response.data[0].id);
          connectToAgent(response.data[0].id);
        }
      }
    } catch (error) {
      console.error('Failed to load agents:', error);
    }
  };

  const connectToAgent = (agentId: string) => {
    if (wsRef.current) wsRef.current.disconnect();
    setMessages([]);

    const ws = createWebSocketClient({
      url: `ws://localhost:3000/ws/agent/${agentId}`,
      onOpen: () => {},
      onClose: () => {},
    });

    ws.onAIMessage(({ message }) => {
      setMessages((prev) => [...prev, message]);
      scrollToBottom();
    });

    ws.onAIStatus(({ status }) => {
      setAgents((prev) => prev.map((a) => (a.id === agentId ? { ...a, status } : a)));
    });

    ws.connect();
    wsRef.current = ws;
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || !activeAgentId || sending) return;

    const userMessage: AIMessage = {
      id: `msg-${Date.now()}`,
      role: 'user',
      content: input,
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setSending(true);
    const messageToSend = input;
    setInput('');

    try {
      await apiClient.sendAIMessage(activeAgentId, messageToSend);
    } catch (error) {
      console.error('Failed to send message:', error);
      setMessages((prev) => [...prev, {
        id: `err-${Date.now()}`,
        role: 'system',
        content: 'Failed to send message. Please try again.',
        timestamp: new Date(),
      }]);
    } finally {
      setSending(false);
    }
  };

  const renderMessage = (message: AIMessage) => (
    <div
      key={message.id}
      className={clsx(
        'flex gap-3 max-w-3xl',
        message.role === 'user' ? 'flex-row-reverse' : 'flex-row'
      )}
    >
      {message.role !== 'user' && (
        <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
          <Bot className="w-4 h-4 text-primary" />
        </div>
      )}
      <div
        className={clsx(
          'rounded-2xl px-4 py-2.5 max-w-[70%]',
          message.role === 'user'
            ? 'bg-primary text-white rounded-br-md'
            : 'bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-white rounded-bl-md'
        )}
      >
        <p className="whitespace-pre-wrap">{message.content}</p>
        <div className="flex items-center gap-2 mt-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <span className="text-xs text-gray-500 dark:text-gray-400">
            {new Date(message.timestamp).toLocaleTimeString()}
          </span>
          <Button variant="ghost" size="icon" className="h-6 w-6 p-0" onClick={() => navigator.clipboard.writeText(message.content)}>
            <Copy className="w-3.5 h-3.5" />
          </Button>
        </div>
      </div>
      {message.role === 'user' && (
        <div className="w-8 h-8 rounded-full bg-gray-200 dark:bg-gray-700 flex items-center justify-center flex-shrink-0">
          <span className="text-xs font-medium text-gray-600 dark:text-gray-400">You</span>
        </div>
      )}
    </div>
  );

  return (
    <div className="flex h-full">
      {/* Agents Sidebar */}
      <aside
        className={clsx(
          'w-64 border-r border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 flex flex-col transition-all duration-300',
          sidebarOpen ? '' : 'w-0 overflow-hidden'
        )}
      >
        <div className="p-4 border-b border-gray-200 dark:border-gray-800 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-primary" />
            <h3 className="font-medium text-gray-900 dark:text-white">AI Agents</h3>
          </div>
          <Button variant="ghost" size="icon" onClick={() => setSidebarOpen(!sidebarOpen)}>
            <X className="w-4 h-4" />
          </Button>
        </div>
        <div className="flex-1 overflow-y-auto p-3 space-y-2">
          {agents.map((agent) => (
            <button
              key={agent.id}
              className={clsx(
                'w-full flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-left',
                activeAgentId === agent.id
                  ? 'bg-primary/10 text-primary'
                  : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800'
              )}
              onClick={() => setActiveAgentId(agent.id)}
            >
              <div className={clsx('w-2 h-2 rounded-full', agent.status === 'running' ? 'bg-green-500 animate-pulse' : 'bg-gray-400')} />
              <div className="flex-1 min-w-0">
                <p className="font-medium truncate">{agent.name}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400 capitalize">{agent.type}</p>
              </div>
            </button>
          ))}
          {agents.length === 0 && (
            <div className="text-center py-8 text-gray-500 dark:text-gray-400">
              <Bot className="w-12 h-12 mx-auto mb-2 opacity-50" />
              <p>No agents configured</p>
            </div>
          )}
        </div>
      </aside>

      {/* Chat Area */}
      <div className="flex-1 flex flex-col">
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {messages.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-full text-center text-gray-500 dark:text-gray-400">
              <Bot className="w-16 h-16 mb-4 opacity-50" />
              <h4 className="text-lg font-medium text-gray-900 dark:text-white mb-2">Start a conversation</h4>
              <p>Select an AI agent from the sidebar to begin chatting</p>
            </div>
          ) : (
            <>
              <div className="space-y-4" role="log" aria-live="polite">
                {messages.map(renderMessage)}
              </div>
              <div ref={messagesEndRef} />
            </>
          )}
        </div>

        {/* Input */}
        <form onSubmit={handleSendMessage} className="p-4 border-t border-gray-200 dark:border-gray-800 bg-white/50 dark:bg-gray-900/50 backdrop-blur-sm">
          <div className="flex gap-2">
            <Input
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="Ask the AI agent..."
              className="flex-1"
              disabled={sending || !activeAgentId}
            />
            <Button type="submit" disabled={!input.trim() || sending || !activeAgentId}>
              {sending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
            </Button>
          </div>
          {!activeAgentId && (
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-2 text-center">
              Select an agent from the sidebar to start chatting
            </p>
          )}
        </form>
      </div>
    </div>
  );
}

function clsx(...inputs: (string | Record<string, boolean> | undefined | null | false)[]): string {
  const classes: string[] = [];
  for (const input of inputs) {
    if (!input) continue;
    if (typeof input === 'string') {
      classes.push(input);
    } else if (typeof input === 'object') {
      for (const [key, value] of Object.entries(input)) {
        if (value) classes.push(key);
      }
    }
  }
  return classes.join(' ');
}