import React, { useState, useEffect } from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet, RefreshControl, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Project } from '@vinhcommand/shared';
import { RESTClient } from '@vinhcommand/api-client';
import { useTheme } from '@/context/ThemeContext';

const apiClient = new RESTClient({ baseUrl: 'http://10.0.2.2:3000' });

export default function ProjectsScreen() {
  const router = useRouter();
  const { resolvedTheme } = useTheme();
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadProjects = async () => {
    try {
      const response = await apiClient.getProjects();
      if (response.success && response.data) {
        setProjects(response.data);
      }
    } catch (error) {
      console.error('Failed to load projects:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadProjects();
  }, []);

  const onRefresh = () => {
    setRefreshing(true);
    loadProjects();
  };

  const handleCreateProject = () => {
    router.push('/project/new');
  };

  const renderProject = ({ item }: { item: Project }) => (
    <TouchableOpacity
      style={styles.projectCard}
      onPress={() => router.push(`/project/${item.id}`)}
      activeOpacity={0.8}
    >
      <View style={styles.projectHeader}>
        <View style={styles.projectIcon}>
          <Ionicons name="code-outline" size={24} color="#3b82f6" />
        </View>
        <View style={styles.projectInfo}>
          <Text style={[styles.projectName, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>
            {item.name}
          </Text>
          <Text style={[styles.projectPath, { color: resolvedTheme === 'dark' ? '#94a3b8' : '#64748b' }]}>
            {item.path}
          </Text>
        </View>
        <Ionicons name="chevron-forward-outline" size={20} color="#94a3b8" />
      </View>
      <View style={styles.projectMeta}>
        <Text style={[styles.metaItem, { color: resolvedTheme === 'dark' ? '#94a3b8' : '#64748b' }]}>
          <Ionicons name="language-outline" size={14} color="#94a3b8" style={{ marginRight: 4 }} />
          {item.language}
        </Text>
        <Text style={[styles.metaItem, { color: resolvedTheme === 'dark' ? '#94a3b8' : '#64748b' }]}>
          <Ionicons name="time-outline" size={14} color="#94a3b8" style={{ marginRight: 4 }} />
          {new Date(item.lastOpenedAt).toLocaleDateString()}
        </Text>
      </View>
    </TouchableOpacity>
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
      <View style={styles.header}>
        <Text style={[styles.headerTitle, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>Projects</Text>
        <TouchableOpacity style={styles.fab} onPress={handleCreateProject}>
          <Ionicons name="add" size={24} color="#fff" />
        </TouchableOpacity>
      </View>
      <FlatList
        data={projects}
        renderItem={renderProject}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            colors={['#3b82f6']}
            tintColor="#3b82f6"
          />
        }
        ListEmptyComponent={
          <View style={[styles.emptyState, { backgroundColor: resolvedTheme === 'dark' ? '#1e293b' : '#f8fafc' }]}>
            <Ionicons name="folder-open-outline" size={64} color="#94a3b8" />
            <Text style={[styles.emptyText, { color: resolvedTheme === 'dark' ? '#94a3b8' : '#64748b' }]}>
              No projects yet
            </Text>
            <Text style={[styles.emptySubtext, { color: resolvedTheme === 'dark' ? '#64748b' : '#94a3b8' }]}>
              Tap + to create your first project
            </Text>
          </View>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    paddingBottom: 10,
  },
  headerTitle: { fontSize: 28, fontWeight: '700' },
  fab: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#3b82f6',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#3b82f6',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 4,
  },
  listContent: { paddingHorizontal: 16, paddingBottom: 100 },
  projectCard: {
    backgroundColor: resolvedTheme => (resolvedTheme === 'dark' ? '#1e293b' : '#fff'),
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 8,
    elevation: 2,
    borderWidth: 1,
    borderColor: resolvedTheme => (resolvedTheme === 'dark' ? '#334155' : '#e2e8f0'),
  },
  projectHeader: { flexDirection: 'row', alignItems: 'center' },
  projectIcon: {
    width: 48,
    height: 48,
    borderRadius: 12,
    backgroundColor: '#eff6ff',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  projectInfo: { flex: 1 },
  projectName: { fontSize: 16, fontWeight: '600' },
  projectPath: { fontSize: 13, marginTop: 2 },
  projectMeta: { flexDirection: 'row', marginTop: 12, paddingTop: 12, borderTopWidth: 1, borderColor: '#e2e8f0' },
  metaItem: { flexDirection: 'row', alignItems: 'center', fontSize: 12, marginRight: 16 },
  emptyState: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 40 },
  emptyText: { fontSize: 18, fontWeight: '600', marginTop: 16 },
  emptySubtext: { fontSize: 14, marginTop: 4 },
  centered: { flex: 1, justifyContent: 'center', alignItems: 'center' },
});