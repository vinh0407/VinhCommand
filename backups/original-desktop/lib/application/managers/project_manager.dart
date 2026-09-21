import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/vinhcommand_core.dart';
import '../../infrastructure/vinhcommand_infrastructure.dart';


class ProjectManager {
  final ProjectRepository _repository;
  final WorkspaceRepository _workspaceRepository;
  final ProjectDiscoveryService _discoveryService;

  ProjectManager(this._repository, this._workspaceRepository)
      : _discoveryService = ProjectDiscoveryService(_repository, _workspaceRepository);

  Future<void> addWorkspace(String path) async {
    await _discoveryService.addWorkspace(path);
  }

  Future<void> removeWorkspace(String path) async {
    await _discoveryService.removeWorkspace(path);
  }

  Future<List<Project>> scanWorkspaces() async {
    return await _discoveryService.scanWorkspaces();
  }

  Future<Project?> getProject(ProjectId id) async {
    return await _repository.getProjectById(id);
  }

  Future<Project?> getProjectByPath(String path) async {
    return await _repository.getProjectByPath(path);
  }

  Future<List<Project>> getAllProjects() async {
    return await _repository.getAllProjects();
  }

  Future<List<Project>> getActiveProjects() async {
    return await _repository.getActiveProjects();
  }

  Future<List<Project>> searchProjects(String query) async {
    return await _repository.searchProjects(query);
  }

  Future<List<Project>> getProjectsByFramework(ProjectFramework framework) async {
    return await _repository.getProjectsByFramework(framework);
  }

  Future<void> updateProjectLastScanned(ProjectId id) async {
    await _repository.updateProjectLastScanned(id, DateTime.now());
  }
}

final projectManagerProvider = Provider<ProjectManager>((ref) {
  throw UnimplementedError('ProjectManager requires repository injection');
});
