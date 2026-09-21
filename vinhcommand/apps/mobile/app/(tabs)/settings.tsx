import React from 'react';
import { View, Text, ScrollView, StyleSheet, Switch, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from '@/context/ThemeContext';
import { useSettings } from '@/context/SettingsContext';

export default function SettingsScreen() {
  const { theme, resolvedTheme, setTheme, toggleTheme } = useTheme();
  const { settings, updateSettings } = useSettings();

  const themeOptions: { value: 'light' | 'dark' | 'system'; label: string; icon: string }[] = [
    { value: 'light', label: 'Light', icon: 'sunny-outline' },
    { value: 'dark', label: 'Dark', icon: 'moon-outline' },
    { value: 'system', label: 'System', icon: 'desktop-outline' },
  ];

  return (
    <ScrollView
      style={[styles.container, { backgroundColor: resolvedTheme === 'dark' ? '#0f172a' : '#fff' }]}
      contentContainerStyle={styles.content}
    >
      <View style={[styles.section, { backgroundColor: resolvedTheme === 'dark' ? '#1e293b' : '#f8fafc' }]}>
        <Text style={[styles.sectionTitle, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>Appearance</Text>

        <View style={styles.settingRow}>
          <Text style={[styles.settingLabel, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>Theme</Text>
          <View style={styles.themeSelector}>
            {themeOptions.map((option) => (
              <TouchableOpacity
                key={option.value}
                style={[
                  styles.themeOption,
                  theme === option.value && styles.themeOptionActive,
                  { backgroundColor: theme === option.value ? '#3b82f6' : resolvedTheme === 'dark' ? '#334155' : '#e2e8f0' },
                ]}
                onPress={() => setTheme(option.value)}
              >
                <Ionicons
                  name={option.icon}
                  size={20}
                  color={theme === option.value ? '#fff' : resolvedTheme === 'dark' ? '#94a3b8' : '#64748b'}
                />
                <Text
                  style={[
                    styles.themeOptionLabel,
                    { color: theme === option.value ? '#fff' : resolvedTheme === 'dark' ? '#94a3b8' : '#64748b' },
                  ]}
                >
                  {option.label}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        <View style={styles.settingRow}>
          <Text style={[styles.settingLabel, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>Font Size</Text>
          <View style={styles.sliderContainer}>
            <Text style={[styles.sliderValue, { color: resolvedTheme === 'dark' ? '#94a3b8' : '#64748b' }]}>
              {settings.fontSize}px
            </Text>
          </View>
        </View>
      </View>

      <View style={[styles.section, { backgroundColor: resolvedTheme === 'dark' ? '#1e293b' : '#f8fafc' }, { marginTop: 16 }]}>
        <Text style={[styles.sectionTitle, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>Editor</Text>

        <View style={styles.settingRow}>
          <View style={styles.toggleContainer}>
            <Text style={[styles.settingLabel, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>Word Wrap</Text>
            <Switch
              value={settings.wordWrap}
              onValueChange={(value) => updateSettings({ wordWrap: value })}
              thumbColor={settings.wordWrap ? '#fff' : '#f4f4f4'}
              trackColor={{ false: '#767577', true: '#3b82f6' }}
            />
          </View>
        </View>

        <View style={styles.settingRow}>
          <View style={styles.toggleContainer}>
            <Text style={[styles.settingLabel, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>Minimap</Text>
            <Switch
              value={settings.minimap}
              onValueChange={(value) => updateSettings({ minimap: value })}
              thumbColor={settings.minimap ? '#fff' : '#f4f4f4'}
              trackColor={{ false: '#767577', true: '#3b82f6' }}
            />
          </View>
        </View>

        <View style={styles.settingRow}>
          <View style={styles.toggleContainer}>
            <Text style={[styles.settingLabel, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>Auto Save</Text>
            <Switch
              value={settings.autoSave}
              onValueChange={(value) => updateSettings({ autoSave: value })}
              thumbColor={settings.autoSave ? '#fff' : '#f4f4f4'}
              trackColor={{ false: '#767577', true: '#3b82f6' }}
            />
          </View>
        </View>

        <View style={styles.settingRow}>
          <Text style={[styles.settingLabel, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>Tab Size</Text>
          <Text style={[styles.settingValue, { color: resolvedTheme === 'dark' ? '#94a3b8' : '#64748b' }]}>
            {settings.tabSize} spaces
          </Text>
        </View>
      </View>

      <View style={[styles.section, { backgroundColor: resolvedTheme === 'dark' ? '#1e293b' : '#f8fafc' }, { marginTop: 16 }]}>
        <Text style={[styles.sectionTitle, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>Terminal</Text>

        <View style={styles.settingRow}>
          <Text style={[styles.settingLabel, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>Default Shell</Text>
          <Text style={[styles.settingValue, { color: resolvedTheme === 'dark' ? '#94a3b8' : '#64748b' }]}>
            {settings.terminalShell}
          </Text>
        </View>
      </View>

      <View style={[styles.section, { backgroundColor: resolvedTheme === 'dark' ? '#1e293b' : '#f8fafc' }, { marginTop: 16 }]}>
        <Text style={[styles.sectionTitle, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>AI</Text>

        <View style={styles.settingRow}>
          <Text style={[styles.settingLabel, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>Provider</Text>
          <Text style={[styles.settingValue, { color: resolvedTheme === 'dark' ? '#94a3b8' : '#64748b' }]}>
            {settings.aiProvider}
          </Text>
        </View>
      </View>

      <View style={[styles.section, { backgroundColor: resolvedTheme === 'dark' ? '#1e293b' : '#f8fafc' }, { marginTop: 16, marginBottom: 32 }]}>
        <Text style={[styles.sectionTitle, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>About</Text>

        <View style={styles.settingRow}>
          <Text style={[styles.settingLabel, { color: resolvedTheme === 'dark' ? '#fff' : '#1e293b' }]}>Version</Text>
          <Text style={[styles.settingValue, { color: resolvedTheme === 'dark' ? '#94a3b8' : '#64748b' }]}>1.0.0</Text>
        </View>

        <TouchableOpacity style={styles.linkButton} onPress={() => {}}>
          <Text style={styles.linkText}>Privacy Policy</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.linkButton} onPress={() => {}}>
          <Text style={styles.linkText}>Terms of Service</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.linkButton} onPress={() => {}}>
          <Text style={styles.linkText}>GitHub Repository</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: { padding: 16 },
  section: { borderRadius: 16, padding: 16 },
  sectionTitle: { fontSize: 18, fontWeight: '700', marginBottom: 16 },
  settingRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 12 },
  settingLabel: { fontSize: 15, fontWeight: '500' },
  settingValue: { fontSize: 15 },
  toggleContainer: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  themeSelector: { flexDirection: 'row', gap: 8 },
  themeOption: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 10,
  },
  themeOptionActive: { shadowColor: '#3b82f6', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.3, shadowRadius: 4, elevation: 2 },
  themeOptionLabel: { fontSize: 13, fontWeight: '600' },
  sliderContainer: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  sliderValue: { fontSize: 15, fontWeight: '600' },
  linkButton: { paddingVertical: 8 },
  linkText: { fontSize: 15, color: '#3b82f6' },
});