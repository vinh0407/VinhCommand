import type { APIResponse, PaginatedResponse, Project, FileNode, TerminalSession, GitStatus, SearchResult } from '@vinhcommand/shared';

export interface RESTClientConfig {
  baseUrl: string;
  timeout?: number;
  headers?: Record<string, string>;
}

export class RESTClient {
  private baseUrl: string;
  private timeout: number;
  private defaultHeaders: Record<string, string>;
  private authToken?: string;

  constructor(config: RESTClientConfig) {
    this.baseUrl = config.baseUrl.replace(/\/+$/, '');
    this.timeout = config.timeout || 30000;
    this.defaultHeaders = {
      'Content-Type': 'application/json',
      ...config.headers,
    };
  }

  setAuthToken(token: string | undefined) {
    this.authToken = token;
  }

  private async request<T>(
    method: string,
    path: string,
    options: { body?: unknown; headers?: Record<string, string>; signal?: AbortSignal } = {}
  ): Promise<APIResponse<T>> {
    const url = `${this.baseUrl}${path}`;
    const headers: Record<string, string> = { ...this.defaultHeaders, ...options.headers };

    if (this.authToken) {
      headers.Authorization = `Bearer ${this.authToken}`;
    }

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeout);

    if (options.signal) {
      options.signal.addEventListener('abort', () => controller.abort());
    }

    try {
      const response = await fetch(url, {
        method,
        headers,
        body: options.body ? JSON.stringify(options.body) : undefined,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      const data = await response.json().catch(() => ({}));

      if (!response.ok) {
        return {
          success: false,
          error: {
            code: `HTTP_${response.status}`,
            message: data.message || response.statusText,
            details: data,
          },
        };
      }

      return { success: true, data: data as T };
    } catch (error) {
      clearTimeout(timeoutId);
      if (error instanceof Error && error.name === 'AbortError') {
        return { success: false, error: { code: 'TIMEOUT', message: 'Request timed out' } };
      }
      return { success: false, error: { code: 'NETWORK_ERROR', message: 'Network error occurred' } };
    }
  }

  async get<T>(path: string, options?: { headers?: Record<string, string>; signal?: AbortSignal }): Promise<APIResponse<T>> {
    return this.request<T>('GET', path, options);
  }

  async post<T>(path: string, body?: unknown, options?: { headers?: Record<string, string>; signal?: AbortSignal }): Promise<APIResponse<T>> {
    return this.request<T>('POST', path, { body, ...options });
  }

  async put<T>(path: string, body?: unknown, options?: { headers?: Record<string, string>; signal?: AbortSignal }): Promise<APIResponse<T>> {
    return this.request<T>('PUT', path, { body, ...options });
  }

  async patch<T>(path: string, body?: unknown, options?: { headers?: Record<string, string>; signal?: AbortSignal }): Promise<APIResponse<T>> {
    return this.request<T>('PATCH', path, { body, ...options });
  }

  async delete<T>(path: string, options?: { headers?: Record<string, string>; signal?: AbortSignal }): Promise<APIResponse<T>> {
    return this.request<T>('DELETE', path, options);
  }

  // Project APIs
  async getProjects(): Promise<APIResponse<Project[]>> {
    return this.get<Project[]>('/api/projects');
  }

  async getProject(id: string): Promise<APIResponse<Project>> {
    return this.get<Project>(`/api/projects/${id}`);
  }

  async createProject(project: Omit<Project, 'id' | 'createdAt' | 'lastOpenedAt'>): Promise<APIResponse<Project>> {
    return this.post<Project>('/api/projects', project);
  }

  async updateProject(id: string, updates: Partial<Project>): Promise<APIResponse<Project>> {
    return this.patch<Project>(`/api/projects/${id}`, updates);
  }

  async deleteProject(id: string): Promise<APIResponse<void>> {
    return this.delete<void>(`/api/projects/${id}`);
  }

  // File System APIs
  async getFileTree(projectId: string, path?: string): Promise<APIResponse<FileNode[]>> {
    const query = path ? `?path=${encodeURIComponent(path)}` : '';
    return this.get<FileNode[]>(`/api/projects/${projectId}/files${query}`);
  }

  async getFileContent(projectId: string, path: string): Promise<APIResponse<{ content: string; encoding: string }>> {
    return this.get<{ content: string; encoding: string }>(`/api/projects/${projectId}/files/content?path=${encodeURIComponent(path)}`);
  }

  async saveFile(projectId: string, path: string, content: string): Promise<APIResponse<void>> {
    return this.post<void>(`/api/projects/${projectId}/files/content`, { path, content });
  }

  async createFile(projectId: string, path: string, content: string = ''): Promise<APIResponse<FileNode>> {
    return this.post<FileNode>(`/api/projects/${projectId}/files`, { path, content });
  }

  async deleteFile(projectId: string, path: string): Promise<APIResponse<void>> {
    return this.delete<void>(`/api/projects/${projectId}/files?path=${encodeURIComponent(path)}`);
  }

  async renameFile(projectId: string, oldPath: string, newPath: string): Promise<APIResponse<FileNode>> {
    return this.post<FileNode>(`/api/projects/${projectId}/files/rename`, { oldPath, newPath });
  }

  // Terminal APIs
  async createTerminalSession(projectId: string, cwd?: string, cols = 80, rows = 24): Promise<APIResponse<TerminalSession>> {
    return this.post<TerminalSession>(`/api/projects/${projectId}/terminal`, { cwd, cols, rows });
  }

  async getTerminalSessions(projectId: string): Promise<APIResponse<TerminalSession[]>> {
    return this.get<TerminalSession[]>(`/api/projects/${projectId}/terminal`);
  }

  async resizeTerminal(projectId: string, sessionId: string, cols: number, rows: number): Promise<APIResponse<void>> {
    return this.post<void>(`/api/projects/${projectId}/terminal/${sessionId}/resize`, { cols, rows });
  }

  async closeTerminal(projectId: string, sessionId: string): Promise<APIResponse<void>> {
    return this.delete<void>(`/api/projects/${projectId}/terminal/${sessionId}`);
  }

  // Git APIs
  async getGitStatus(projectId: string): Promise<APIResponse<GitStatus>> {
    return this.get<GitStatus>(`/api/projects/${projectId}/git/status`);
  }

  async getGitLog(projectId: string, limit = 50): Promise<APIResponse<GitCommit[]>> {
    return this.get<GitCommit[]>(`/api/projects/${projectId}/git/log?limit=${limit}`);
  }

  async gitCommit(projectId: string, message: string, files?: string[]): Promise<APIResponse<GitCommit>> {
    return this.post<GitCommit>(`/api/projects/${projectId}/git/commit`, { message, files });
  }

  async gitPush(projectId: string, remote = 'origin', branch?: string): Promise<APIResponse<void>> {
    return this.post<void>(`/api/projects/${projectId}/git/push`, { remote, branch });
  }

  async gitPull(projectId: string, remote = 'origin', branch?: string): Promise<APIResponse<void>> {
    return this.post<void>(`/api/projects/${projectId}/git/pull`, { remote, branch });
  }

  // Search APIs
  async search(projectId: string, query: string, options?: { path?: string; caseSensitive?: boolean; regex?: boolean }): Promise<APIResponse<SearchResult[]>> {
    return this.post<SearchResult[]>(`/api/projects/${projectId}/search`, { query, ...options });
  }

  // AI APIs
  async sendAIMessage(agentId: string, message: string, context?: Record<string, unknown>): Promise<APIResponse<void>> {
    return this.post<void>(`/api/agents/${agentId}/message`, { message, context });
  }

  async getAIAgents(): Promise<APIResponse<AIAgent[]>> {
    return this.get<AIAgent[]>('/api/agents');
  }

  async createAIAgent(agent: Omit<AIAgent, 'id' | 'status'>): Promise<APIResponse<AIAgent>> {
    return this.post<AIAgent>('/api/agents', agent);
  }

  async deleteAIAgent(agentId: string): Promise<APIResponse<void>> {
    return this.delete<void>(`/api/agents/${agentId}`);
  }
}

export interface AIAgent {
  id: string;
  name: string;
  type: 'codex' | 'antigravity' | 'custom';
  status: 'idle' | 'running' | 'waiting' | 'error';
  currentProjectId?: string;
  config: Record<string, unknown>;
}

export interface GitCommit {
  hash: string;
  shortHash: string;
  message: string;
  author: string;
  email: string;
  date: string;
  files: GitFileChange[];
}

export interface GitFileChange {
  path: string;
  status: 'added' | 'modified' | 'deleted' | 'renamed' | 'copied';
  additions: number;
  deletions: number;
}