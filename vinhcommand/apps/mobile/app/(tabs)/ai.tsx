import React, { useState, useEffect } from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet, TextInput, ScrollView, ActivityIndicator } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { AIMessage, AIAgent } from '@vinhcommand/shared';
import { RESTClient, createWebSocketClient } from '@vinhcommand/api-client';
import { useTheme } from '@/context/ThemeContext';

const apiClient = new RESTClient({ baseUrl: 'http://10.0.2.2:3000' });

export default function AIScreen() {
  const { resolvedTheme } = useTheme();
  const [agents, setAgents] = useState<AIAgent[]>([]);
  const [activeAgentId, setActiveAgentId] = useState<string | null>(null);
  const [messages, setMessages] = useState<AIMessage[]>([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const wsRef = React.useRef<ReturnType<typeof createWebSocketClient> | null>(null);
  const scrollViewRef = useRef<ScrollView>(null);

  useEffect(() => {
    loadAgents();
    return () => wsRef.current?.disconnect();
  }, []);

  const loadAgents = async () => {
    try {
      const response = await apiClient.getAIAgents();
      if (response.success && response.data) {
        setAgents(response.data);
        if (response.data.length > 0) {
          setActiveAgentId(response.data[0].id);
          connectToAgent(response.data[0].id);
        }
      }
    } catch (error) {
      console.error('Failed to load agents:', error);
    } finally {
      setLoading(false);
    }
  };

  const connectToAgent = (agentId: string) => {
    if (wsRef.current) wsRef.current.disconnect();

    const ws = createWebSocketClient({
      url: `ws://10.0.2.2:3000/ws/agent/${agentId}`,
      onOpen: () => {},
      onClose: () => {},
    });

    ws.onAIMessage(({ message }) => {
      setMessages((prev) => [...prev, message]);
      setTimeout(() => scrollViewRef.current?.scrollToEnd({ animated: true }), 0);
    });

    ws.onAIStatus(({ status }) => {
      setAgents((prev) => prev.map((a) => (a.id === agentId ? { ...a, status } : a)));
    });

    ws.connect();
    wsRef.current = ws;
  };

  const handleSendMessage = async () => {
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
    } finally {
      setSending(false);
    }
  };

  const renderMessage = ({ item }: { item: AIMessage }) => (
    <View
      style={[
        styles.messageContainer,
        item.role === 'user' ? styles.userMessage : styles.assistantMessage,
      ]}
    >
      <View
        style={[
          styles.messageBubble,
          item.role === 'user' ? styles.userBubble : styles.assistantBubble,
          { backgroundColor: item.role === 'user' ? '#3b82f6' : resolvedTheme === 'dark' ? '#1e293b' : '#f1f5f9' },
        ]}
      >
        <Text
          style={[
            styles.messageText,
            { color: item.role === 'user' ? '#fff' : resolvedTheme === 'dark' ? '#e6edf3' : '#1e293b' },
          ]}
        >
          {item.content}
        </Text>
      </View>
      <Text
        style={[
          styles.messageTime,
          { color: resolvedTheme === 'dark' ? '#64748b' : '#94a3b8' },
        ]}
      >
        {new Date(item.timestamp).toLocaleTimeString()}
      </Text>
    </View>
  );

  if (loading) {
    return (
      <View style={[styles.centered, { backgroundColor: resolvedTheme === 'dark' ? '#0f172a' : '#fff' }]}>
        <ActivityIndicator size="large" color="#3b82f6" />
      </View>
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: resolvedTheme === 'dark' ? '#0f172a' : '#fff' }]}>
      <View style={[styles.header, { backgroundColor: resolvedTheme === 'dark' ? '#1e293b' : '#f8fafc' }]}>
        <Text style={[styles.headerTitle, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>AI Agents</Text>
      </View>

      <ScrollView
        ref={scrollViewRef}
        style={[styles.messagesContainer, { backgroundColor: resolvedTheme === 'dark' ? '#0f172a' : '#fff' }]}
        contentContainerStyle={styles.messagesContent}
        keyboardShouldPersistTaps="handled"
      >
        <FlatList
          data={messages}
          renderItem={renderMessage}
          keyExtractor={(item) => item.id}
          ListEmptyComponent={
            <View style={[styles.emptyState, { backgroundColor: resolvedTheme === 'dark' ? '#0f172a' : '#fff' }]}>
              <Ionicons name="cube-outline" size={64} color="#94a3b8" />
              <Text style={[styles.emptyText, { color: resolvedTheme === 'dark' ? '#94a3b8' : '#64748b' }]}>
                No messages yet
              </Text>
              <Text style={[styles.emptySubtext, { color: resolvedTheme === 'dark' ? '#64748b' : '#94a3b8' }]}>
                Select an agent and start chatting
              </Text>
            </View>
          }
        />
      </ScrollView>

      <View style={[styles.inputContainer, { backgroundColor: resolvedTheme === 'dark' ? '#1e293b' : '#f8fafc' }]}>
        <TextInput
          style={[
            styles.input,
            { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b', backgroundColor: resolvedTheme === 'dark' ? '#0f172a' : '#fff' },
          ]}
          value={input}
          onChangeText={setInput}
          onSubmitEditing={handleSendMessage}
          placeholder="Ask AI agent..."
          placeholderTextColor="#64748b"
          multiline
          maxLength={2000}
        />
        <TouchableOpacity style={styles.sendButton} onPress={handleSendMessage} disabled={!input.trim() || sending}>
          <Ionicons name={sending ? 'hourglass-outline' : 'send-outline'} size={24} color="#fff" />
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, flexDirection: 'column' },
  header: { padding: 16, borderBottomWidth: 1, borderColor: '#334155' },
  headerTitle: { fontSize: 20, fontWeight: '700' },
  messagesContainer: { flex: 1 },
  messagesContent: { padding: 16, paddingBottom: 20 },
  messageContainer: { marginBottom: 16, maxWidth: '85%' },
  userMessage: { alignSelf: 'flex-end' },
  assistantMessage: { alignSelf: 'flex-start' },
  messageBubble: { padding: 12, borderRadius: 16 },
  userBubble: { borderBottomRightRadius: 4 },
  assistantBubble: { borderBottomLeftRadius: 4 },
  messageText: { fontSize: 15, lineHeight: 22 },
  messageTime: { fontSize: 11, marginTop: 4, marginHorizontal: 4 },
  emptyState: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 40 },
  emptyText: { fontSize: 18, fontWeight: '600', marginTop: 16 },
  emptySubtext: { fontSize: 14, marginTop: 4 },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    padding: 12,
    borderTopWidth: 1,
    borderColor: '#334155',
    gap: 8,
  },
  input: {
    flex: 1,
    fontSize: 15,
    padding: 12,
    borderRadius: 24,
    maxHeight: 120,
    minHeight: 48,
  },
  sendButton: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#3b82f6',
    justifyContent: 'center',
    alignItems: 'center',
  },
  centered: { flex: 1, justifyContent: 'center', alignItems: 'center' },
});