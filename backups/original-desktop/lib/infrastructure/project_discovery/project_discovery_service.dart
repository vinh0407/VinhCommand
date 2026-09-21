import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:convert' show jsonDecode;
import '../../core/vinhcommand_core.dart';

class ProjectDiscoveryService {
  static const Map<ProjectFramework, List<String>> _frameworkMarkers = {
    ProjectFramework.flutter: ['pubspec.yaml'],
    ProjectFramework.react: ['package.json'],
    ProjectFramework.nextjs: ['package.json', 'next.config.js', 'next.config.ts'],
    ProjectFramework.vite: ['package.json', 'vite.config.js', 'vite.config.ts'],
    ProjectFramework.nodejs: ['package.json'],
    ProjectFramework.python: ['pyproject.toml', 'requirements.txt', 'setup.py'],
    ProjectFramework.fastapi: ['pyproject.toml', 'requirements.txt', 'main.py'],
    ProjectFramework.django: ['manage.py', 'settings.py'],
    ProjectFramework.java: ['pom.xml'],
    ProjectFramework.spring: ['pom.xml', 'build.gradle', 'settings.gradle'],
    ProjectFramework.android: ['build.gradle', 'settings.gradle', 'build.gradle.kts'],
    ProjectFramework.dotnet: ['*.csproj', '*.sln'],
    ProjectFramework.csharp: ['*.csproj', '*.sln'],
    ProjectFramework.cpp: ['CMakeLists.txt', 'Makefile'],
    ProjectFramework.go: ['go.mod'],
    ProjectFramework.rust: ['Cargo.toml'],
    ProjectFramework.electron: ['package.json'],
  };

  final ProjectRepository _projectRepository;
  final WorkspaceRepository _workspaceRepository;
  final List<String> _workspacePaths = [];

  ProjectDiscoveryService(this._projectRepository, this._workspaceRepository);

  Future<void> addWorkspace(String path) async {
    final canonicalPath = await _getCanonicalPath(path);
    if (!_workspacePaths.contains(canonicalPath)) {
      _workspacePaths.add(canonicalPath);
      
      final workspace = Workspace(
        id: canonicalPath.hashCode.toString(),
        name: p.basename(canonicalPath),
        path: canonicalPath,
        enabled: true,
        addedAt: DateTime.now(),
      );
      
      await _workspaceRepository.saveWorkspace(workspace);
    }
  }

  Future<void> removeWorkspace(String path) async {
    final canonicalPath = await _getCanonicalPath(path);
    _workspacePaths.remove(canonicalPath);
    
    final workspace = await _workspaceRepository.getWorkspaceByPath(canonicalPath);
    if (workspace != null) {
      await _workspaceRepository.deleteWorkspace(workspace.id);
    }
  }

  Future<List<Project>> scanWorkspaces() async {
    final allProjects = <Project>[];

    for (final workspacePath in _workspacePaths) {
      if (await Directory(workspacePath).exists()) {
        final projects = await _scanDirectory(workspacePath);
        allProjects.addAll(projects);
      }
    }

    for (final project in allProjects) {
      await _projectRepository.saveProject(project);
    }

    return allProjects;
  }

  Future<List<Project>> _scanDirectory(String rootPath) async {
    final projects = <Project>[];
    final dir = Directory(rootPath);

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is Directory) {
          final project = await _checkForProject(entity.path);
          if (project != null) {
            projects.add(project);
          }
        }
      }
    } catch (e) {
      throw ProjectDiscoveryException(message: 'Failed to scan $rootPath: $e');
    }

    return projects;
  }

  Future<Project?> _checkForProject(String dirPath) async {
    for (final entry in _frameworkMarkers.entries) {
      final framework = entry.key;
      final markers = entry.value;

      for (final marker in markers) {
        if (marker.contains('*')) {
          final pattern = marker.replaceAll('*', '');
          final files = Directory(dirPath).listSync()
              .where((e) => e is File && e.path.endsWith(pattern))
              .toList();
          if (files.isNotEmpty) {
            return await _createProject(dirPath, framework);
          }
        } else {
          final markerPath = p.join(dirPath, marker);
          if (await File(markerPath).exists()) {
            return await _createProject(dirPath, framework);
          }
        }
      }
    }

    return null;
  }

  Future<Project> _createProject(String rootPath, ProjectFramework framework) async {
    final name = p.basename(rootPath);
    final id = ProjectId.generate();
    
    final gitInfo = await _getGitInfo(rootPath);
    final scripts = await _getScripts(rootPath, framework);
    final commands = await _getCommands(rootPath, framework);
    final ports = await _detectPorts(rootPath);
    final languages = await _detectLanguages(rootPath);
    final packageManager = await _detectPackageManager(rootPath, framework);

    return Project(
      id: id,
      name: name,
      rootPath: rootPath,
      framework: framework,
      languages: languages,
      packageManager: packageManager,
      gitInfo: gitInfo,
      branch: gitInfo?.currentBranch,
      scripts: scripts,
      buildCommands: commands['build'] ?? [],
      testCommands: commands['test'] ?? [],
      devCommands: commands['dev'] ?? [],
      ports: ports,
      processes: [],
      agents: [],
      discoveredAt: DateTime.now(),
    );
  }

  Future<GitInfo?> _getGitInfo(String path) async {
    try {
      final gitDir = Directory(p.join(path, '.git'));
      if (!await gitDir.exists()) return null;

      final process = await Process.run('git', ['status', '--porcelain'], workingDirectory: path);
      final statusOutput = process.stdout.toString();

      final branchProcess = await Process.run('git', ['branch', '--show-current'], workingDirectory: path);
      final branch = branchProcess.stdout.toString().trim();

      final remoteProcess = await Process.run('git', ['remote', 'get-url', 'origin'], workingDirectory: path);
      final remoteUrl = remoteProcess.stdout.toString().trim();

      final logProcess = await Process.run('git', ['log', '-1', '--format=%H|%s|%ai'], workingDirectory: path);
      final logOutput = logProcess.stdout.toString().trim();
      String? lastCommitHash;
      String? lastCommitMessage;
      DateTime? lastCommitAt;
      
      if (logOutput.isNotEmpty) {
        final parts = logOutput.split('|');
        if (parts.length >= 3) {
          lastCommitHash = parts[0];
          lastCommitMessage = parts[1];
          lastCommitAt = DateTime.tryParse(parts[2]);
        }
      }

      final aheadBehindProcess = await Process.run('git', ['rev-list', '--left-right', '--count', 'HEAD...@{u}'], workingDirectory: path);
      int ahead = 0;
      int behind = 0;
      if (aheadBehindProcess.exitCode == 0) {
        final parts = aheadBehindProcess.stdout.toString().trim().split('\t');
        if (parts.length == 2) {
          ahead = int.tryParse(parts[0]) ?? 0;
          behind = int.tryParse(parts[1]) ?? 0;
        }
      }

      final staged = statusOutput.split('\n').where((l) => l.startsWith('M') || l.startsWith('A')).length;
      final unstaged = statusOutput.split('\n').where((l) => l.startsWith(' M') || l.startsWith(' D')).length;
      final untracked = statusOutput.split('\n').where((l) => l.startsWith('??')).length;

      return GitInfo(
        remoteUrl: remoteUrl,
        currentBranch: branch,
        isClean: statusOutput.trim().isEmpty,
        stagedFiles: staged,
        unstagedFiles: unstaged,
        untrackedFiles: untracked,
        ahead: ahead,
        behind: behind,
        lastCommitAt: lastCommitAt,
        lastCommitHash: lastCommitHash,
        lastCommitMessage: lastCommitMessage,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _getScripts(String path, ProjectFramework framework) async {
    final scripts = <String, String>{};
    
    if ([ProjectFramework.nodejs, ProjectFramework.react, ProjectFramework.nextjs, 
         ProjectFramework.vite, ProjectFramework.electron].contains(framework)) {
      final pkgPath = p.join(path, 'package.json');
      if (await File(pkgPath).exists()) {
        final content = await File(pkgPath).readAsString();
        try {
          final json = jsonDecode(content);
          if (json['scripts'] != null) {
            final Map<String, dynamic> scriptMap = json['scripts'];
            scriptMap.forEach((key, value) => scripts[key] = value.toString());
          }
        } catch (_) {}
      }
    }

    return scripts;
  }

  Future<Map<String, List<String>>> _getCommands(String path, ProjectFramework framework) async {
    final commands = <String, List<String>>{
      'build': [],
      'test': [],
      'dev': [],
    };

    switch (framework) {
      case ProjectFramework.flutter:
        commands['build'] = ['flutter build'];
        commands['test'] = ['flutter test'];
        commands['dev'] = ['flutter run'];
        break;
      case ProjectFramework.react:
      case ProjectFramework.nextjs:
      case ProjectFramework.vite:
      case ProjectFramework.nodejs:
      case ProjectFramework.electron:
        commands['build'] = ['npm run build', 'yarn build', 'pnpm build'];
        commands['test'] = ['npm test', 'yarn test', 'pnpm test'];
        commands['dev'] = ['npm run dev', 'yarn dev', 'pnpm dev'];
        break;
      case ProjectFramework.python:
      case ProjectFramework.fastapi:
      case ProjectFramework.django:
        commands['test'] = ['pytest', 'python -m pytest'];
        commands['dev'] = ['python main.py', 'python manage.py runserver'];
        break;
      case ProjectFramework.java:
      case ProjectFramework.spring:
        commands['build'] = ['./mvnw clean install', './gradlew build'];
        commands['test'] = ['./mvnw test', './gradlew test'];
        break;
      case ProjectFramework.android:
        commands['build'] = ['./gradlew assembleDebug'];
        commands['test'] = ['./gradlew test'];
        break;
      case ProjectFramework.dotnet:
      case ProjectFramework.csharp:
        commands['build'] = ['dotnet build'];
        commands['test'] = ['dotnet test'];
        commands['dev'] = ['dotnet run'];
        break;
      case ProjectFramework.go:
        commands['build'] = ['go build'];
        commands['test'] = ['go test ./...'];
        commands['dev'] = ['go run .'];
        break;
      case ProjectFramework.rust:
        commands['build'] = ['cargo build'];
        commands['test'] = ['cargo test'];
        commands['dev'] = ['cargo run'];
        break;
      default:
        break;
    }

    return commands;
  }

  Future<List<int>> _detectPorts(String path) async {
    final ports = <int>[];
    const commonPorts = [3000, 3001, 5173, 8080, 8081, 4200, 5000, 5001, 8000, 8001];
    
    for (final port in commonPorts) {
      if (await _isPortInUse(port)) {
        ports.add(port);
      }
    }

    return ports;
  }

  Future<bool> _isPortInUse(int port) async {
    try {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
      await server.close();
      return false;
    } catch (_) {
      return true;
    }
  }

  Future<List<String>> _detectLanguages(String path) async {
    final languages = <String>[];
    final files = await _getAllFiles(path);
    
    final extensions = files.map((f) => p.extension(f.path).toLowerCase()).toSet();
    
    if (extensions.contains('.dart')) languages.add('Dart');
    if (extensions.contains('.js') || extensions.contains('.jsx')) languages.add('JavaScript');
    if (extensions.contains('.ts') || extensions.contains('.tsx')) languages.add('TypeScript');
    if (extensions.contains('.py')) languages.add('Python');
    if (extensions.contains('.java')) languages.add('Java');
    if (extensions.contains('.kt') || extensions.contains('.kts')) languages.add('Kotlin');
    if (extensions.contains('.cs')) languages.add('C#');
    if (extensions.contains('.cpp') || extensions.contains('.cc') || extensions.contains('.cxx')) languages.add('C++');
    if (extensions.contains('.go')) languages.add('Go');
    if (extensions.contains('.rs')) languages.add('Rust');
    if (extensions.contains('.swift')) languages.add('Swift');
    
    return languages;
  }

  Future<List<FileSystemEntity>> _getAllFiles(String path) async {
    final files = <FileSystemEntity>[];
    final dir = Directory(path);
    
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        files.add(entity);
      }
    }
    
    return files;
  }

  Future<String?> _detectPackageManager(String path, ProjectFramework framework) async {
    if ([ProjectFramework.nodejs, ProjectFramework.react, ProjectFramework.nextjs, 
         ProjectFramework.vite, ProjectFramework.electron].contains(framework)) {
      if (await File(p.join(path, 'pnpm-lock.yaml')).exists()) return 'pnpm';
      if (await File(p.join(path, 'yarn.lock')).exists()) return 'yarn';
      if (await File(p.join(path, 'package-lock.json')).exists()) return 'npm';
      return 'npm';
    }
    
    if ([ProjectFramework.python, ProjectFramework.fastapi, ProjectFramework.django].contains(framework)) {
      if (await File(p.join(path, 'pyproject.toml')).exists()) {
        final content = await File(p.join(path, 'pyproject.toml')).readAsString();
        if (content.contains('poetry')) return 'poetry';
        if (content.contains('uv')) return 'uv';
      }
      return 'pip';
    }
    
    return null;
  }

  Future<String> _getCanonicalPath(String path) async {
    final file = File(path);
    final dir = Directory(path);
    
    if (await file.exists()) {
      return file.resolveSymbolicLinksSync();
    } else if (await dir.exists()) {
      return dir.resolveSymbolicLinksSync();
    }
    
    return path;
  }
}

class ProjectDiscoveryException extends VinhCommandException {
const ProjectDiscoveryException({
    required String message,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
        code: 'PROJECT_DISCOVERY_FAILED',
        message: message,
        suggestedAction: suggestedAction,
        technicalDetails: technicalDetails,
        stackTrace: stackTrace,
      );
}


