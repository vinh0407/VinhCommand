import { useEffect, useRef, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { FolderOpen, Save, ChevronLeft, X, Search, Terminal, Bot } from 'lucide-react';
import { Button, Input } from '@vinhcommand/ui-core';
import { RESTClient } from '@vinhcommand/api-client';
import { FileNode } from '@vinhcommand/shared';
import * as monaco from 'monaco-editor';

const apiClient = new RESTClient({ baseUrl: 'http://localhost:3000' });

declare global {
  interface Window {
    monaco: typeof monaco;
  }
}

window.monaco = monaco;

export function EditorView() {
  const { projectId } = useParams();
  const navigate = useNavigate();
  const [files, setFiles] = useState<FileNode[]>([]);
  const [openTabs, setOpenTabs] = useState<Array<{ id: string; path: string; name: string; content: string; dirty: boolean }>>([]);
  const [activeTabId, setActiveTabId] = useState<string | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const editorRef = useRef<monaco.editor.IStandaloneCodeEditor | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const loading = !projectId || projectId === 'new';

  useEffect(() => {
    if (projectId && projectId !== 'new') {
      loadFileTree(projectId);
    }
  }, [projectId]);

  const loadFileTree = async (pid: string) => {
    try {
      const response = await apiClient.getFileTree(pid);
      if (response.success && response.data) {
        setFiles(response.data);
      }
    } catch (error) {
      console.error('Failed to load file tree:', error);
    }
  };

  const openFile = async (file: FileNode) => {
    if (file.type === 'directory') {
      setFiles((prev) => toggleExpanded(prev, file.id));
      return;
    }

    const existingTab = openTabs.find((t) => t.path === file.path);
    if (existingTab) {
      setActiveTabId(existingTab.id);
      return;
    }

    try {
      const response = await apiClient.getFileContent(projectId!, file.path);
      if (response.success && response.data) {
        const newTab = {
          id: file.id,
          path: file.path,
          name: file.name,
          content: response.data.content,
          dirty: false,
        };
        setOpenTabs((prev) => [...prev, newTab]);
        setActiveTabId(file.id);
      }
    } catch (error) {
      console.error('Failed to open file:', error);
    }
  };

  const toggleExpanded = (nodes: FileNode[], id: string): FileNode[] => {
    return nodes.map((node) => {
      if (node.id === id) {
        return { ...node, isExpanded: !node.isExpanded };
      }
      if (node.children) {
        return { ...node, children: toggleExpanded(node.children, id) };
      }
      return node;
    });
  };

  const handleSave = async () => {
    const activeTab = openTabs.find((t) => t.id === activeTabId);
    if (!activeTab || !activeTab.dirty) return;

    try {
      await apiClient.saveFile(projectId!, activeTab.path, activeTab.content);
      setOpenTabs((prev) =>
        prev.map((t) => (t.id === activeTabId ? { ...t, dirty: false } : t))
      );
    } catch (error) {
      console.error('Failed to save file:', error);
    }
  };

  const handleCloseTab = (tabId: string) => {
    setOpenTabs((prev) => prev.filter((t) => t.id !== tabId));
    if (activeTabId === tabId) {
      const remaining = openTabs.filter((t) => t.id !== tabId);
      setActiveTabId(remaining.length > 0 ? remaining[remaining.length - 1].id : null);
    }
  };

  const handleContentChange = (content: string) => {
    setOpenTabs((prev) =>
      prev.map((t) => (t.id === activeTabId ? { ...t, content, dirty: true } : t))
    );
  };

  useEffect(() => {
    if (!containerRef.current || editorRef.current) return;

    const editor = monaco.editor.create(containerRef.current, {
      value: openTabs.find((t) => t.id === activeTabId)?.content || '',
      language: getLanguageFromPath(activeTabId ? openTabs.find((t) => t.id === activeTabId)?.path : ''),
      theme: 'vs-dark',
      automaticLayout: true,
      minimap: { enabled: true },
      fontSize: 14,
      fontFamily: 'JetBrains Mono, Fira Code, Consolas, monospace',
      tabSize: 2,
      wordWrap: 'on',
      lineNumbers: 'on',
      scrollBeyondLastLine: false,
    });

    editorRef.current = editor;

    editor.onDidChangeModelContent(() => {
      handleContentChange(editor.getValue());
    });

    return () => {
      editor.dispose();
      editorRef.current = null;
    };
  }, []);

  useEffect(() => {
    if (editorRef.current && activeTabId) {
      const tab = openTabs.find((t) => t.id === activeTabId);
      if (tab) {
        editorRef.current.setValue(tab.content);
        editorRef.current.setModelLanguage(getLanguageFromPath(tab.path));
      }
    }
  }, [activeTabId]);

  const getLanguageFromPath = (path: string) => {
    const ext = path.split('.').pop()?.toLowerCase();
    const langs: Record<string, string> = {
      ts: 'typescript',
      tsx: 'typescriptreact',
      js: 'javascript',
      jsx: 'javascriptreact',
      json: 'json',
      html: 'html',
      css: 'css',
      scss: 'scss',
      py: 'python',
      rs: 'rust',
      go: 'go',
      java: 'java',
      md: 'markdown',
    };
    return langs[ext || ''] || 'plaintext';
  };

  const renderFileTree = (nodes: FileNode[], depth = 0) => (
    <div>
      {nodes.map((node) => (
        <div key={node.id} style={{ paddingLeft: depth * 16 }}>
          {node.type === 'directory' ? (
            <div
              className="flex items-center gap-1 px-2 py-1 hover:bg-gray-100 dark:hover:bg-gray-800 rounded cursor-pointer"
              onClick={() => openFile(node)}
            >
              <ChevronLeft
                className={clsx('w-4 h-4 text-gray-400 transition-transform', node.isExpanded && 'rotate-90')}
              />
              <FolderOpen className="w-4 h-4 text-yellow-500" />
              <span className="text-sm truncate">{node.name}</span>
            </div>
          ) : (
            <div
              className={clsx(
                'flex items-center gap-2 px-2 py-1 rounded cursor-pointer transition-colors',
                activeTabId === node.id
                  ? 'bg-primary/10 text-primary'
                  : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800'
              )}
              onClick={() => openFile(node)}
            >
              <FileText className="w-4 h-4 text-gray-400" />
              <span className="text-sm truncate flex-1">{node.name}</span>
            </div>
          )}
          {node.isExpanded && node.children && renderFileTree(node.children, depth + 1)}
        </div>
      ))}
    </div>
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
      </div>
    );
  }

  return (
    <div className="flex h-full overflow-hidden">
      {/* File Explorer Sidebar */}
      <aside
        className={clsx(
          'w-72 border-r border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 flex flex-col transition-all duration-300',
          sidebarOpen ? '' : 'w-0 overflow-hidden'
        )}
      >
        <div className="p-3 border-b border-gray-200 dark:border-gray-800 flex items-center justify-between">
          <h3 className="font-medium text-gray-900 dark:text-white">Explorer</h3>
          <div className="flex items-center gap-1">
            <Input
              placeholder="Search files..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-40"
              leftIcon={<Search className="w-4 h-4" />}
            />
          </div>
        </div>
        <div className="flex-1 overflow-y-auto p-2">
          {renderFileTree(files)}
        </div>
      </aside>

      {/* Editor Area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Tab Bar */}
        <div className="flex items-center h-10 px-3 bg-gray-50 dark:bg-gray-900/50 border-b border-gray-200 dark:border-gray-800">
          <div className="flex-1 flex items-center gap-1 overflow-x-auto">
            {openTabs.map((tab) => (
              <div
                key={tab.id}
                className={clsx(
                  'flex items-center gap-2 px-3 py-1.5 rounded-t-lg text-sm transition-colors whitespace-nowrap',
                  activeTabId === tab.id
                    ? 'bg-white dark:bg-gray-800 text-gray-900 dark:text-white border-b-2 border-transparent'
                    : 'bg-gray-100 dark:bg-gray-800/50 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700'
                )}
                onClick={() => setActiveTabId(tab.id)}
              >
                <span className="truncate max-w-[150px]">{tab.name}{tab.dirty && ' ●'}</span>
                <button
                  className="p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-700 opacity-0 group-hover:opacity-100"
                  onClick={(e) => { e.stopPropagation(); handleCloseTab(tab.id); }}
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              </div>
            ))}
          </div>
          <div className="flex items-center gap-2">
            <Button variant="ghost" size="icon" onClick={handleSave} disabled={!openTabs.find((t) => t.id === activeTabId)?.dirty}>
              <Save className="w-4 h-4" />
            </Button>
          </div>
        </div>

        {/* Editor */}
        <div className="flex-1 relative" ref={containerRef} />
      </div>
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