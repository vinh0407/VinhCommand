import '../entities/project.dart';
import '../value_objects/ids.dart';
import '../enums/project_framework.dart';

abstract class ProjectRepository {
  Future<List<Project>> getAllProjects();

  Future<Project?> getProjectById(ProjectId id);

  Future<Project?> getProjectByPath(String path);

  Future<Project> saveProject(Project project);

  Future<void> deleteProject(ProjectId id);

  Future<void> updateProjectLastScanned(ProjectId id, DateTime scannedAt);

  Future<List<Project>> getActiveProjects();

  Future<List<Project>> searchProjects(String query);

  Future<List<Project>> getProjectsByFramework(ProjectFramework framework);
}

abstract class WorkspaceRepository {
  Future<List<Workspace>> getAllWorkspaces();

  Future<Workspace?> getWorkspaceById(String id);

  Future<Workspace?> getWorkspaceByPath(String path);

  Future<Workspace> saveWorkspace(Workspace workspace);

  Future<void> deleteWorkspace(String id);

  Future<void> updateWorkspaceLastScanned(String id, DateTime scannedAt);

  Future<void> updateWorkspaceProjectCount(String id, int count);
}