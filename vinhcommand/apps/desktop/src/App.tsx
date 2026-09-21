import { Routes, Route, Navigate } from 'react-router-dom';
import { Layout } from './components/Layout';
import { ProjectsView } from './components/ProjectsView';
import { EditorView } from './components/EditorView';
import { TerminalView } from './components/TerminalView';
import { AIView } from './components/AIView';
import { SettingsView } from './components/SettingsView';
import { useTheme } from './context/ThemeContext';

function App() {
  const { resolvedTheme } = useTheme();

  return (
    <div className={`h-screen w-screen ${resolvedTheme === 'dark' ? 'dark' : ''}`}>
      <Routes>
        <Route path="/" element={<Navigate to="/projects" replace />} />
        <Route element={<Layout />}>
          <Route path="/projects" element={<ProjectsView />} />
          <Route path="/editor/:projectId?" element={<EditorView />} />
          <Route path="/terminal/:projectId?" element={<TerminalView />} />
          <Route path="/ai" element={<AIView />} />
          <Route path="/settings" element={<SettingsView />} />
        </Route>
      </Routes>
    </div>
  );
}

export default App;