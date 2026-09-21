import { useEffect, useRef, useState } from 'react';
import { useParams } from 'react-router-dom';
import { Plus, X, Trash2, Maximize2, Minimize2, Send, Square } from 'lucide-react';
import { Button, Input } from '@vinhcommand/ui-core';
import { RESTClient, createWebSocketClient } from '@vinhcommand/api-client';
import { TerminalSession } from '@vinhcommand/shared';

const apiClient = new RESTClient({ baseUrl: 'http://localhost:3000' });

export function TerminalView() {
  const { projectId } = useParams();
  const [sessions, setSessions] = useState<TerminalSession[]>([]);
  const [activeSessionId, setActiveSessionId] = useState<string | null>(null);
  const [output, setOutput] = useState<string>('');
  const [input, setInput] = useState('');
  const [connected, setConnected] = useState(false);
  const [maximized, setMaximized] = useState(false);
  const wsRef = useRef<ReturnType<typeof createWebSocketClient> | null>(null);
  const outputRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (projectId) {
      loadSessions();
    }
    return () => {
      wsRef.current?.disconnect();
    };
  }, [projectId]);

  const loadSessions = async () => {
    try {
      const response = await apiClient.getTerminalSessions(projectId!);
      if (response.success && response.data) {
        setSessions(response.data);
        if (response.data.length > 0 && !activeSessionId) {
          setActiveSessionId(response.data[0].id);
          connectToSession(response.data[0].id);
        }
      }
    } catch (error) {
      console.error('Failed to load sessions:', error);
    }
  };

  const createSession = async () => {
    try {
      const response = await apiClient.createTerminalSession(projectId!);
      if (response.success && response.data) {
        setSessions((prev) => [...prev, response.data!]);
        setActiveSessionId(response.data.id);
        connectToSession(response.data.id);
      }
    } catch (error) {
      console.error('Failed to create session:', error);
    }
  };

  const connectToSession = (sessionId: string) => {
    if (wsRef.current) {
      wsRef.current.disconnect();
    }

    setOutput('');

    const ws = createWebSocketClient({
      url: `ws://localhost:3000/ws/terminal/${sessionId}`,
      onOpen: () => setConnected(true),
      onClose: () => setConnected(false),
    });

    ws.onTerminalOutput(({ data }) => {
      setOutput((prev) => prev + data);
      setTimeout(() => outputRef.current?.scrollTo({ top: outputRef.current.scrollHeight }), 0);
    });

    ws.onTerminalExit(({ exitCode }) => {
      setOutput((prev) => prev + `\r\n[Process exited with code ${exitCode}]\r\n`);
      setConnected(false);
    });

    ws.connect();
    wsRef.current = ws;
  };

  const handleSendInput = (e: React.FormEvent) => {
    e.preventDefault();
    if (wsRef.current && input.trim()) {
      wsRef.current.send('terminal:input', { data: input + '\r' });
      setInput('');
    }
  };

  const closeSession = async (sessionId: string) => {
    if (wsRef.current) {
      wsRef.current.disconnect();
    }
    try {
      await apiClient.closeTerminal(projectId!, sessionId);
      setSessions((prev) => prev.filter((s) => s.id !== sessionId));
      if (activeSessionId === sessionId) {
        const remaining = sessions.filter((s) => s.id !== sessionId);
        if (remaining.length > 0) {
          setActiveSessionId(remaining[0].id);
          connectToSession(remaining[0].id);
        } else {
          setActiveSessionId(null);
        }
      }
    } catch (error) {
      console.error('Failed to close session:', error);
    }
  };

  return (
    <div className={clsx('flex h-full flex-col', maximized && 'fixed inset-0 z-50 bg-gray-900')}>
      {/* Header */}
      <div className="flex items-center justify-between h-10 px-3 bg-gray-100 dark:bg-gray-900/50 border-b border-gray-200 dark:border-gray-800">
        <div className="flex items-center gap-2">
          <h3 className="font-medium text-gray-900 dark:text-white">Terminal</h3>
          {activeSessionId && (
            <span className="px-2 py-0.5 text-xs rounded bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-400">
              {sessions.find((s) => s.id === activeSessionId)?.name || 'bash'}
            </span>
          )}
        </div>
        <div className="flex items-center gap-1">
          <Button variant="ghost" size="icon" onClick={createSession} title="New Terminal">
            <Plus className="w-4 h-4" />
          </Button>
          <Button variant="ghost" size="icon" onClick={() => setMaximized(!maximized)} title={maximized ? 'Minimize' : 'Maximize'}>
            {maximized ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
          </Button>
        </div>
      </div>

      {/* Session Tabs */}
      {sessions.length > 0 && (
        <div className="flex px-2 py-1 bg-gray-50 dark:bg-gray-900/50 border-b border-gray-200 dark:border-gray-800 overflow-x-auto">
          {sessions.map((session) => (
            <button
              key={session.id}
              className={clsx(
                'flex items-center gap-2 px-3 py-1.5 text-sm rounded-lg transition-colors whitespace-nowrap',
                activeSessionId === session.id
                  ? 'bg-white dark:bg-gray-800 text-gray-900 dark:text-white'
                  : 'text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700'
              )}
              onClick={() => setActiveSessionId(session.id)}
            >
              <span className={clsx('w-2 h-2 rounded-full', session.id === activeSessionId ? 'bg-green-500' : 'bg-gray-400')} />
              <span>{session.name}</span>
              <button
                className="p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-700 opacity-0 group-hover:opacity-100"
                onClick={(e) => { e.stopPropagation(); closeSession(session.id); }}
              >
                <Trash2 className="w-3.5 h-3.5" />
              </button>
            </button>
          ))}
        </div>
      )}

      {/* Terminal Output */}
      <div
        className="flex-1 relative bg-gray-950 overflow-hidden"
        ref={outputRef}
      >
        <pre className="p-4 font-mono text-sm text-gray-100 whitespace-pre-wrap break-all">
          {output || (
            <span className="text-gray-500">
              No active terminal session. Click "New Terminal" to start one.
            </span>
          )}
          <span className={clsx('relative', connected ? 'text-green-500' : 'text-red-500')}>
            █
          </span>
        </pre>
      </div>

      {/* Input */}
      <form onSubmit={handleSendInput} className="flex items-center gap-2 p-3 bg-gray-100 dark:bg-gray-900/50 border-t border-gray-200 dark:border-gray-800">
        <span className="text-green-500 font-mono">$</span>
        <Input
          ref={inputRef}
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Type a command..."
          className="flex-1 bg-transparent border-0 focus:ring-0 text-gray-900 dark:text-white placeholder-gray-500"
        />
        <Button type="submit" variant="ghost" size="icon" disabled={!input.trim() || !connected}>
          <Send className="w-4 h-4" />
        </Button>
      </form>
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