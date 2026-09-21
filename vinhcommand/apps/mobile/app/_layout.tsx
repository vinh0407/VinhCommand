import { Stack } from 'expo-router';
import { ThemeProvider } from '@/context/ThemeContext';
import { SettingsProvider } from '@/context/SettingsContext';
import { useColorScheme } from 'react-native';
import { StatusBar } from 'expo-status-bar';

export default function RootLayout() {
  const colorScheme = useColorScheme();

  return (
    <ThemeProvider defaultTheme="system">
      <SettingsProvider>
        <Stack
          screenOptions={{
            headerShown: false,
            contentStyle: { backgroundColor: colorScheme === 'dark' ? '#0f172a' : '#ffffff' },
          }}
        >
          <Stack.Screen name="(tabs)" options={{ presentation: 'modal' }} />
          <Stack.Screen name="project/[id]" options={{ presentation: 'push' }} />
          <Stack.Screen name="settings" options={{ presentation: 'push' }} />
        </Stack>
        <StatusBar
          style={colorScheme === 'dark' ? 'light' : 'dark'}
          backgroundColor={colorScheme === 'dark' ? '#0f172a' : '#ffffff'}
        />
      </SettingsProvider>
    </ThemeProvider>
  );
}