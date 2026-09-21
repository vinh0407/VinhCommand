import React, { createContext, useContext, useState, useEffect, useCallback, ReactNode } from 'react';
import { useColorScheme } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

type Theme = 'light' | 'dark' | 'system';

interface ThemeContextValue {
  theme: Theme;
  resolvedTheme: 'light' | 'dark';
  setTheme: (theme: Theme) => void;
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined);

export function ThemeProvider({ children, defaultTheme = 'system' }: { children: ReactNode; defaultTheme?: Theme }) {
  const systemColorScheme = useColorScheme();
  const [theme, setThemeState] = useState<Theme>(defaultTheme);
  const [resolvedTheme, setResolvedTheme] = useState<'light' | 'dark'>('light');
  const [loaded, setLoaded] = useState(false);

  const updateResolvedTheme = useCallback((newTheme: Theme) => {
    let resolved: 'light' | 'dark' = 'light';
    if (newTheme === 'system') {
      resolved = systemColorScheme === 'dark' ? 'dark' : 'light';
    } else {
      resolved = newTheme;
    }
    setResolvedTheme(resolved);
  }, [systemColorScheme]);

  useEffect(() => {
    AsyncStorage.getItem('theme').then((stored) => {
      if (stored) {
        setThemeState(stored as Theme);
      }
      setLoaded(true);
    });
  }, []);

  useEffect(() => {
    if (loaded) {
      updateResolvedTheme(theme);
      AsyncStorage.setItem('theme', theme);
    }
  }, [theme, loaded, updateResolvedTheme]);

  useEffect(() => {
    if (theme === 'system' && loaded) {
      updateResolvedTheme('system');
    }
  }, [systemColorScheme, theme, loaded, updateResolvedTheme]);

  const setTheme = useCallback((newTheme: Theme) => {
    setThemeState(newTheme);
  }, []);

  const toggleTheme = useCallback(() => {
    setThemeState((prev) => {
      if (prev === 'light') return 'dark';
      if (prev === 'dark') return 'system';
      return 'light';
    });
  }, []);

  if (!loaded) {
    return null;
  }

  return (
    <ThemeContext.Provider value={{ theme, resolvedTheme, setTheme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
}