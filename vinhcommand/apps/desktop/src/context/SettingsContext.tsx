import React, { createContext, useContext, useState, useEffect, useCallback, ReactNode } from 'react';
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
  terminalShell: 'powershell',
  aiProvider: 'codex',
};

const SettingsContext = createContext<SettingsContextValue | undefined>(undefined);

export function SettingsProvider({ children }: { children: ReactNode }) {
  const [settings, setSettings] = useState<WorkspaceSettings>(() => {
    if (typeof window === 'undefined') return defaultSettings;
    try {
      const stored = localStorage.getItem('workspace-settings');
      return stored ? { ...defaultSettings, ...JSON.parse(stored) } : defaultSettings;
    } catch {
      return defaultSettings;
    }
  });

  const updateSettings = useCallback((newSettings: Partial<WorkspaceSettings>) => {
    setSettings((prev) => {
      const updated = { ...prev, ...newSettings };
      if (typeof window !== 'undefined') {
        localStorage.setItem('workspace-settings', JSON.stringify(updated));
      }
      return updated;
    });
  }, []);

  const resetSettings = useCallback(() => {
    setSettings(defaultSettings);
    if (typeof window !== 'undefined') {
      localStorage.removeItem('workspace-settings');
    }
  }, []);

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