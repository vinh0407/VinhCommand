import { Tabs } from 'expo-router';
import { useColorScheme } from 'react-native';
import React from 'react';
import { View, Text } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

const tabBarIcons = {
  projects: 'folder-outline',
  terminal: 'terminal-outline',
  ai: 'cube-outline',
  settings: 'settings-outline',
};

export default function TabLayout() {
  const colorScheme = useColorScheme();

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: '#3b82f6',
        tabBarInactiveTintColor: colorScheme === 'dark' ? '#94a3b8' : '#64748b',
        tabBarStyle: {
          backgroundColor: colorScheme === 'dark' ? '#1e293b' : '#f8fafc',
          borderTopWidth: 0,
          elevation: 8,
          shadowColor: '#000',
          shadowOffset: { width: 0, height: -2 },
          shadowOpacity: 0.1,
          shadowRadius: 8,
        },
        tabBarLabelStyle: { fontSize: 11, fontWeight: '600' },
      }}
    >
      <Tabs.Screen
        name="projects"
        options={{
          title: 'Projects',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name={tabBarIcons.projects} size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="terminal"
        options={{
          title: 'Terminal',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name={tabBarIcons.terminal} size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="ai"
        options={{
          title: 'AI Agents',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name={tabBarIcons.ai} size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'Settings',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name={tabBarIcons.settings} size={size} color={color} />
          ),
        }}
      />
    </Tabs>
  );
}