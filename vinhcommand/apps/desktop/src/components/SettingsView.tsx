import { useState } from 'react';
import { Sun, Moon, Monitor, Save, RotateCcw } from 'lucide-react';
import { Button, Card, CardHeader, CardTitle, CardDescription, CardContent, Input, Switch } from '@vinhcommand/ui-core';
import { useTheme } from '../context/ThemeContext';
import { useSettings } from '../context/SettingsContext';

const themeOptions = [
  { value: 'light' as const, label: 'Light', icon: Sun, description: 'Always use light mode' },
  { value: 'dark' as const, label: 'Dark', icon: Moon, description: 'Always use dark mode' },
  { value: 'system' as const, label: 'System', icon: Monitor, description: 'Match system preference' },
];

export function SettingsView() {
  const { theme, resolvedTheme, setTheme } = useTheme();
  const { settings, updateSettings, resetSettings } = useSettings();
  const [fontSize, setFontSize] = useState(settings.fontSize);
  const [tabSize, setTabSize] = useState(settings.tabSize);

  const handleFontSizeChange = (value: number) => {
    setFontSize(value);
    updateSettings({ fontSize: value });
  };

  const handleTabSizeChange = (value: number) => {
    setTabSize(value);
    updateSettings({ tabSize: value });
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Settings</h1>
        <p className="text-gray-500 dark:text-gray-400 mt-1">Customize your VinhCommand experience</p>
      </div>

      {/* Appearance */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Sun className="w-5 h-5 text-primary" />
            <div>
              <CardTitle>Appearance</CardTitle>
              <CardDescription>Customize how VinhCommand looks</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">Theme</label>
            <div className="grid grid-cols-3 gap-3">
              {themeOptions.map((option) => {
                const Icon = option.icon;
                const isActive = theme === option.value;
                return (
                  <button
                    key={option.value}
                    className={clsx(
                      'relative p-4 rounded-xl border-2 transition-all duration-200 flex flex-col items-center gap-2',
                      isActive
                        ? 'border-primary bg-primary/5'
                        : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
                    )}
                    onClick={() => setTheme(option.value)}
                  >
                    <div className={clsx('w-10 h-10 rounded-lg flex items-center justify-center', isActive ? 'bg-primary' : 'bg-gray-100 dark:bg-gray-800')}>
                      <Icon className={clsx('w-5 h-5', isActive ? 'text-white' : 'text-gray-600 dark:text-gray-400')} />
                    </div>
                    <span className={clsx('font-medium', isActive ? 'text-primary' : 'text-gray-900 dark:text-white')}>
                      {option.label}
                    </span>
                    <span className="text-xs text-gray-500 dark:text-gray-400 text-center">{option.description}</span>
                    {isActive && (
                      <div className="absolute -top-2 -right-2 w-5 h-5 rounded-full bg-primary flex items-center justify-center">
                        <span className="w-3 h-3 bg-white rounded-full" />
                      </div>
                    )}
                  </button>
                );
              })}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
              Font Size: {fontSize}px
            </label>
            <input
              type="range"
              min="10"
              max="24"
              value={fontSize}
              onChange={(e) => handleFontSizeChange(Number(e.target.value))}
              className="w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-lg appearance-none cursor-pointer accent-primary"
            />
          </div>
        </CardContent>
      </Card>

      {/* Editor */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Save className="w-5 h-5 text-primary" />
            <div>
              <CardTitle>Editor</CardTitle>
              <CardDescription>Configure editor behavior</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="flex items-center justify-between">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Word Wrap</label>
                <p className="text-xs text-gray-500 dark:text-gray-400">Wrap long lines to next line</p>
              </div>
              <Switch
                checked={settings.wordWrap}
                onCheckedChange={(checked) => updateSettings({ wordWrap: checked })}
              />
            </div>

            <div className="flex items-center justify-between">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Minimap</label>
                <p className="text-xs text-gray-500 dark:text-gray-400">Show code minimap on the right</p>
              </div>
              <Switch
                checked={settings.minimap}
                onCheckedChange={(checked) => updateSettings({ minimap: checked })}
              />
            </div>

            <div className="flex items-center justify-between">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Auto Save</label>
                <p className="text-xs text-gray-500 dark:text-gray-400">Automatically save changes</p>
              </div>
              <Switch
                checked={settings.autoSave}
                onCheckedChange={(checked) => updateSettings({ autoSave: checked })}
              />
            </div>

            <div className="flex items-center justify-between">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Tab Size: {tabSize} spaces</label>
                <p className="text-xs text-gray-500 dark:text-gray-400">Number of spaces per tab</p>
              </div>
              <select
                value={tabSize}
                onChange={(e) => handleTabSizeChange(Number(e.target.value))}
                className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent"
              >
                {[2, 4, 8].map((size) => (
                  <option key={size} value={size}>{size} spaces</option>
                ))}
              </select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Terminal */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Save className="w-5 h-5 text-primary" />
            <div>
              <CardTitle>Terminal</CardTitle>
              <CardDescription>Configure terminal settings</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Default Shell</label>
            <Input
              value={settings.terminalShell}
              onChange={(e) => updateSettings({ terminalShell: e.target.value })}
              placeholder="e.g., powershell, cmd, bash, zsh"
            />
          </div>
        </CardContent>
      </Card>

      {/* AI */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Save className="w-5 h-5 text-primary" />
            <div>
              <CardTitle>AI</CardTitle>
              <CardDescription>Configure AI agent settings</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Default AI Provider</label>
            <select
              value={settings.aiProvider}
              onChange={(e) => updateSettings({ aiProvider: e.target.value as any })}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent"
            >
              <option value="codex">Codex</option>
              <option value="antigravity">Antigravity</option>
              <option value="openai">OpenAI</option>
              <option value="anthropic">Anthropic</option>
            </select>
          </div>
        </CardContent>
      </Card>

      {/* Danger Zone */}
      <Card variant="outlined" className="border-red-200 dark:border-red-900/30">
        <CardHeader>
          <div className="flex items-center gap-2">
            <RotateCcw className="w-5 h-5 text-red-500" />
            <div>
              <CardTitle className="text-red-600 dark:text-red-400">Danger Zone</CardTitle>
              <CardDescription>Irreversible actions</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Button
            variant="danger"
            onClick={() => {
              if (confirm('Are you sure you want to reset all settings to defaults?')) {
                resetSettings();
                setFontSize(14);
                setTabSize(2);
              }
            }}
          >
            <RotateCcw className="w-4 h-4 mr-2" />
            Reset All Settings
          </Button>
        </CardContent>
      </Card>
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