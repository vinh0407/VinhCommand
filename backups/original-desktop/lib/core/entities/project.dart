import 'package:equatable/equatable.dart';
import '../enums/project_framework.dart';
import '../value_objects/ids.dart';

class Project extends Equatable {
  final ProjectId id;
  final String name;
  final String rootPath;
  final ProjectFramework framework;
  final List<String> languages;
  final String? packageManager;
  final GitInfo? gitInfo;
  final String? branch;
  final Map<String, String> scripts;
  final List<String> buildCommands;
  final List<String> testCommands;
  final List<String> devCommands;
  final List<int> ports;
  final List<String> processes;
  final List<String> agents;
  final DateTime discoveredAt;
  final DateTime? lastScannedAt;
  final bool isActive;

  const Project({
    required this.id,
    required this.name,
    required this.rootPath,
    required this.framework,
    required this.languages,
    this.packageManager,
    this.gitInfo,
    this.branch,
    required this.scripts,
    required this.buildCommands,
    required this.testCommands,
    required this.devCommands,
    required this.ports,
    required this.processes,
    required this.agents,
    required this.discoveredAt,
    this.lastScannedAt,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        rootPath,
        framework,
        languages,
        packageManager,
        gitInfo,
        branch,
        scripts,
        buildCommands,
        testCommands,
        devCommands,
        ports,
        processes,
        agents,
        discoveredAt,
        lastScannedAt,
        isActive,
      ];

  Project copyWith({
    ProjectId? id,
    String? name,
    String? rootPath,
    ProjectFramework? framework,
    List<String>? languages,
    String? packageManager,
    GitInfo? gitInfo,
    String? branch,
    Map<String, String>? scripts,
    List<String>? buildCommands,
    List<String>? testCommands,
    List<String>? devCommands,
    List<int>? ports,
    List<String>? processes,
    List<String>? agents,
    DateTime? discoveredAt,
    DateTime? lastScannedAt,
    bool? isActive,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      rootPath: rootPath ?? this.rootPath,
      framework: framework ?? this.framework,
      languages: languages ?? this.languages,
      packageManager: packageManager ?? this.packageManager,
      gitInfo: gitInfo ?? this.gitInfo,
      branch: branch ?? this.branch,
      scripts: scripts ?? this.scripts,
      buildCommands: buildCommands ?? this.buildCommands,
      testCommands: testCommands ?? this.testCommands,
      devCommands: devCommands ?? this.devCommands,
      ports: ports ?? this.ports,
      processes: processes ?? this.processes,
      agents: agents ?? this.agents,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get hasGit => gitInfo != null;

  String get displayFramework => framework.label;
}

class GitInfo extends Equatable {
  final String remoteUrl;
  final String currentBranch;
  final bool isClean;
  final int stagedFiles;
  final int unstagedFiles;
  final int untrackedFiles;
  final int ahead;
  final int behind;
  final DateTime? lastCommitAt;
  final String? lastCommitHash;
  final String? lastCommitMessage;

  const GitInfo({
    required this.remoteUrl,
    required this.currentBranch,
    required this.isClean,
    required this.stagedFiles,
    required this.unstagedFiles,
    required this.untrackedFiles,
    required this.ahead,
    required this.behind,
    this.lastCommitAt,
    this.lastCommitHash,
    this.lastCommitMessage,
  });

  @override
  List<Object?> get props => [
        remoteUrl,
        currentBranch,
        isClean,
        stagedFiles,
        unstagedFiles,
        untrackedFiles,
        ahead,
        behind,
        lastCommitAt,
        lastCommitHash,
        lastCommitMessage,
      ];

  int get totalChanges => stagedFiles + unstagedFiles + untrackedFiles;

  bool get hasRemoteChanges => ahead > 0 || behind > 0;
}

class Workspace extends Equatable {
  final String id;
  final String name;
  final String path;
  final bool enabled;
  final DateTime addedAt;
  final DateTime? lastScannedAt;
  final int projectCount;

  const Workspace({
    required this.id,
    required this.name,
    required this.path,
    required this.enabled,
    required this.addedAt,
    this.lastScannedAt,
    this.projectCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        path,
        enabled,
        addedAt,
        lastScannedAt,
        projectCount,
      ];
}