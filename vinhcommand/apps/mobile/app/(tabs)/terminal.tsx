import React, { useState, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, ScrollView, TextInput, TouchableOpacity, Keyboard } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { WebSocketClient, createWebSocketClient } from '@vinhcommand/api-client';
import { TerminalSession, TerminalOutput } from '@vinhcommand/shared';
import { useTheme } from '@/context/ThemeContext';
import { RESTClient } from '@vinhcommand/api-client';

const apiClient = new RESTClient({ baseUrl: 'http://10.0.2.2:3000' });

export default function TerminalScreen() {
  const { resolvedTheme } = useTheme();
  const [sessions, setSessions] = useState<TerminalSession[]>([]);
  const [activeSessionId, setActiveSessionId] = useState<string | null>(null);
  const [output, setOutput] = useState<string>('');
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(true);
  const [connected, setConnected] = useState(false);
  const wsRef = useRef<WebSocketClient | null>(null);
  const scrollViewRef = useRef<ScrollView>(null);
  const inputRef = useRef<TextInput>(null);

  useEffect(() => {
    loadSessions();
    return () => {
      wsRef.current?.disconnect();
    };
  }, []);

  const loadSessions = async () => {
    try {
      const response = await apiClient.getTerminalSessions('default');
      if (response.success && response.data) {
        setSessions(response.data);
        if (response.data.length > 0 && !activeSessionId) {
          setActiveSessionId(response.data[0].id);
          connectToSession(response.data[0].id);
        }
      }
    } catch (error) {
      console.error('Failed to load sessions:', error);
    } finally {
      setLoading(false);
    }
  };

  const createSession = async () => {
    try {
      const response = await apiClient.createTerminalSession('default');
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

    const ws = createWebSocketClient({
      url: `ws://10.0.2.2:3000/ws/terminal/${sessionId}`,
      onOpen: () => setConnected(true),
      onClose: () => setConnected(false),
    });

    ws.onTerminalOutput(({ data }) => {
      setOutput((prev) => prev + data);
      setTimeout(() => scrollViewRef.current?.scrollToEnd({ animated: true }), 0);
    });

    ws.onTerminalExit(({ exitCode }) => {
      setOutput((prev) => prev + `\r\n[Process exited with code ${exitCode}]\r\n`);
      setConnected(false);
    });

    ws.connect();
    wsRef.current = ws;
  };

  const handleSendInput = () => {
    if (wsRef.current && input.trim()) {
      wsRef.current.send('terminal:input', { data: input + '\r' });
      setInput('');
    }
  };

  const handleKeyPress = (event: { nativeEvent: { key: string } }) => {
    if (event.nativeEvent.key === 'Enter') {
      handleSendInput();
    }
  };

  return (
    <View style={[styles.container, { backgroundColor: resolvedTheme === 'dark' ? '#0f172a' : '#fff' }]}>
      <View style={[styles.header, { backgroundColor: resolvedTheme === 'dark' ? '#1e293b' : '#f8fafc' }]}>
        <Text style={[styles.headerTitle, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>Terminal</Text>
        <View style={styles.headerActions}>
          <TouchableOpacity style={styles.iconButton} onPress={createSession}>
            <Ionicons name="add-circle-outline" size={24} color="#3b82f6" />
          </TouchableOpacity>
          {sessions.length > 1 && (
            <TouchableOpacity style={styles.iconButton} onPress={() => {}}>
              <Ionicons name="square-outline" size={24} color="#94a3b8" />
            </TouchableOpacity>
          )}
        </View>
      </View>

      {sessions.length > 0 && (
        <ScrollView
          ref={scrollViewRef}
          style={[styles.outputContainer, { backgroundColor: resolvedTheme === 'dark' ? '#0d1117' : '#1e1e1e' }]}
          contentContainerStyle={styles.outputContent}
          keyboardShouldPersistTaps="handled"
        >
          <Text
            style={[
              styles.outputText,
              { color: resolvedTheme === 'dark' ? '#e6edf3' : '#d4d4d4' },
            ]}
            selectable={true}
          >
            {output || 'No output yet...'}
            <Text style={{ color: connected ? '#3fb950' : '#f85149' }}> █</Text>
          </Text>
        </ScrollView>
      )}

      <View style={[styles.inputContainer, { backgroundColor: resolvedTheme === 'dark' ? '#1e293b' : '#f8fafc' }]}>
        <Text style={[styles.prompt, { color: '#3fb950' }]}>$</Text>
        <TextInput
          ref={inputRef}
          style={[styles.input, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}
          value={input}
          onChangeText={setInput}
          onKeyPress={handleKeyPress}
          placeholder="Type a command..."
          placeholderTextColor="#64748b"
          autoFocus={true}
          blurOnSubmit={false}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, flexDirection: 'column' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 16, borderBottomWidth: 1, borderColor: '#334155' },
  headerTitle: { fontSize: 20, fontWeight: '700' },
  headerActions: { flexDirection: 'row', gap: 8 },
  iconButton: { padding: 8 },
  outputContainer: { flex: 1 },
  outputContent: { padding: 16, minHeight: '100%' },
  outputText: { fontFamily: 'monospace', fontSize: 14, lineHeight: 22 },
  inputContainer: { flexDirection: 'row', alignItems: 'center', padding: 12, borderTopWidth: 1, borderColor: '#334155' },
  prompt: { fontFamily: 'monospace', fontSize: 14, marginRight: 8 },
  input: { flex: 1, fontFamily: 'monospace', fontSize: 14, paddingVertical: 4 },
});