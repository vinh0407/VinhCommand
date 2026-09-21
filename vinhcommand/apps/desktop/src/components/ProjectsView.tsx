import { useState, useEffect } from 'react';
import { Plus, FolderGit, Search, MoreVertical, Clock, Code, FileText } from 'lucide-react';
import { Button, Card, CardHeader, CardTitle, CardContent, Input } from '@vinhcommand/ui-core';
import { RESTClient } from '@vinhcommand/api-client';
import { Project } from '@vinhcommand/shared';
import { useNavigate } from 'react-router-dom';

const apiClient = new RESTClient({ baseUrl: 'http://localhost:3000' });

export function ProjectsView() {
  const navigate = useNavigate();
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    loadProjects();
  }, []);

  const loadProjects = async () => {
    try {
      const response = await apiClient.getProjects();
      if (response.success && response.data) {
        setProjects(response.data);
      }
    } catch (error) {
      console.error('Failed to load projects:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateProject = () => {
    navigate('/editor/new');
  };

  const handleOpenProject = (project: Project) => {
    navigate(`/editor/${project.id}`);
  };

  const filteredProjects = projects.filter((p) =>
    p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    p.path.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Projects</h1>
          <p className="text-gray-500 dark:text-gray-400 mt-1">Manage your development projects</p>
        </div>
        <Button onClick={handleCreateProject} leftIcon={<Plus className="w-4 h-4" />}>
          New Project
        </Button>
      </div>

      <div className="flex gap-4">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <Input
            placeholder="Search projects..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10"
          />
        </div>
      </div>

      {loading ? (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {[...Array(6)].map((_, i) => (
            <Card key={i} variant="default" className="animate-pulse">
              <CardContent className="space-y-4">
                <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4" />
                <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/2" />
                <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/4" />
              </CardContent>
            </Card>
          ))}
        </div>
      ) : filteredProjects.length === 0 ? (
        <Card variant="outlined" className="py-12 text-center">
          <FolderGit className="w-16 h-16 mx-auto text-gray-300 dark:text-gray-600 mb-4" />
          <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">No projects found</h3>
          <p className="text-gray-500 dark:text-gray-400 mb-4">
            {searchQuery ? 'Try adjusting your search' : 'Get started by creating your first project'}
          </p>
          <Button onClick={handleCreateProject} leftIcon={<Plus className="w-4 h-4" />}>
            Create Project
          </Button>
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {filteredProjects.map((project) => (
            <Card
              key={project.id}
              variant="default"
              hoverable
              onClick={() => handleOpenProject(project)}
            >
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-xl bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                      <Code className="w-6 h-6 text-blue-600 dark:text-blue-400" />
                    </div>
                    <div>
                      <CardTitle className="text-base">{project.name}</CardTitle>
                      <p className="text-xs text-gray-500 dark:text-gray-400 truncate max-w-[200px]">{project.path}</p>
                    </div>
                  </div>
                  <MoreVertical className="w-4 h-4 text-gray-400 opacity-0 group-hover:opacity-100 transition-opacity" />
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400">
                  <FileText className="w-3.5 h-3.5" />
                  <span>{project.language}</span>
                  {project.framework && (
                    <>
                      <span>•</span>
                      <span className="px-2 py-0.5 text-xs bg-gray-100 dark:bg-gray-800 rounded">{project.framework}</span>
                    </>
                  )}
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400">
                  <Clock className="w-3.5 h-3.5" />
                  <span>Last opened {new Date(project.lastOpenedAt).toLocaleDateString()}</span>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}