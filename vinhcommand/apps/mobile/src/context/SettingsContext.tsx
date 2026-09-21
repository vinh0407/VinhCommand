import React, { createContext, useContext, useState, useEffect, useCallback, ReactNode } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { WorkspaceSettings } from '@vinhcommand/shared';

interface SettingsContextValue {
  settings: WorkspaceSettings;
  updateSettings: (settings: Partial<WorkspaceSettings>) => void;
  resetSettings: () => void;
}

const defaultSettings: WorkspaceSettings = {
  theme: 'system',
  fontSize: 14,
  fontFamily: 'JetBrains Mono, Fira Code, Consolas, monospace',
  tabSize: 2,
  wordWrap: true,
  minimap: true,
  autoSave: true,
  terminalShell: 'zsh',
  aiProvider: 'codex',
};

const SettingsContext = createContext<SettingsContextValue | undefined>(undefined);

export function SettingsProvider({ children }: { children: ReactNode }) {
  const [settings, setSettings] = useState<WorkspaceSettings>(defaultSettings);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem('workspace-settings').then((stored) => {
      if (stored) {
        try {
          setSettings({ ...defaultSettings, ...JSON.parse(stored) });
        } catch {
          setSettings(defaultSettings);
        }
      }
      setLoaded(true);
    });
  }, []);

  const updateSettings = useCallback((newSettings: Partial<WorkspaceSettings>) => {
    setSettings((prev) => {
      const updated = { ...prev, ...newSettings };
      AsyncStorage.setItem('workspace-settings', JSON.stringify(updated));
      return updated;
    });
  }, []);

  const resetSettings = useCallback(() => {
    setSettings(defaultSettings);
    AsyncStorage.removeItem('workspace-settings');
  }, []);

  if (!loaded) {
    return null;
  }

  return (
    <SettingsContext.Provider value={{ settings, updateSettings, resetSettings }}>
      {children}
    </SettingsContext.Provider>
  );
}

export function useSettings() {
  const context = useContext(SettingsContext);
  if (!context) {
    throw new Error('useSettings must be used within a SettingsProvider');
  }
  return context;
}