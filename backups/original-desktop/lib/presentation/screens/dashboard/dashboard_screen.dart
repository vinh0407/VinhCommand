import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vinhcommand_desktop/application/vinhcommand_application.dart';
import 'package:vinhcommand_desktop/core/vinhcommand_core.dart';
import 'package:vinhcommand_desktop/presentation/vinhcommand_presentation.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemInfoAsync = ref.watch(systemInfoProvider);
    final agentsAsync = ref.watch(agentsProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final processesAsync = ref.watch(processesProvider);
    final serversAsync = ref.watch(serversProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSystemSection(systemInfoAsync),
          const SizedBox(height: 24),
          _buildAgentsSection(agentsAsync),
          const SizedBox(height: 24),
          _buildProjectsSection(projectsAsync),
          const SizedBox(height: 24),
          _buildTasksSection(tasksAsync),
          const SizedBox(height: 24),
          _buildDevelopmentSection(processesAsync, serversAsync),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'AI Agent Command Center',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh All'),
          onPressed: () {
            // Refresh all providers
          },
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New Task'),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSystemSection(AsyncValue<SystemInfo> systemInfoAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('SYSTEM', Icons.computer),
        const SizedBox(height: 12),
        systemInfoAsync.when(
          data: (info) => Row(
            children: [
              Expanded(child: SystemStatsCard.cpu(info)),
              const SizedBox(width: 12),
              Expanded(child: SystemStatsCard.memory(info)),
              const SizedBox(width: 12),
              Expanded(child: SystemStatsCard.gpu(info)),
              const SizedBox(width: 12),
              Expanded(child: SystemStatsCard.disk(info)),
              const SizedBox(width: 12),
              Expanded(child: SystemStatsCard.network(info)),
            ],
          ),
          loading: () => const _LoadingCardRow(count: 5),
          error: (e, _) => _ErrorCardRow(error: e.toString()),
        ),
      ],
    );
  }

  Widget _buildAgentsSection(AsyncValue<List<Agent>> agentsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionHeader('AI AGENTS', Icons.smart_toy),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Agent'),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        agentsAsync.when(
          data: (agents) => Row(
            children: agents.map((agent) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AgentStatusCard(agent: agent),
              ),
            )).toList(),
          ),
          loading: () => const _LoadingCardRow(count: 4),
          error: (e, _) => _ErrorCardRow(error: e.toString()),
        ),
      ],
    );
  }

  Widget _buildProjectsSection(AsyncValue<List<Project>> projectsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionHeader('PROJECTS', Icons.folder),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Workspace'),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        projectsAsync.when(
          data: (projects) {
            if (projects.isEmpty) {
              return _EmptyState(
                icon: Icons.folder_open,
                title: 'No Projects Found',
                subtitle: 'Add a workspace to discover projects',
                actionLabel: 'Add Workspace',
                onAction: () {},
              );
            }
            return Row(
              children: projects.take(4).map((project) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ProjectSummaryCard(project: project),
                ),
              )).toList(),
            );
          },
          loading: () => const _LoadingCardRow(count: 4),
          error: (e, _) => _ErrorCardRow(error: e.toString()),
        ),
      ],
    );
  }

  Widget _buildTasksSection(AsyncValue<List<Task>> tasksAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionHeader('TASKS', Icons.task_alt),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Task'),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        tasksAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return _EmptyState(
                icon: Icons.task,
                title: 'No Tasks',
                subtitle: 'Create a task to start AI agent work',
                actionLabel: 'Create Task',
                onAction: () {},
              );
            }
            return Row(
              children: [
                Expanded(child: TaskSummaryCard(tasks: tasks)),
              ],
            );
          },
          loading: () => const _LoadingCardRow(count: 1),
          error: (e, _) => _ErrorCardRow(error: e.toString()),
        ),
      ],
    );
  }

  Widget _buildDevelopmentSection(
    AsyncValue<List<ProcessInfo>> processesAsync,
    AsyncValue<List<DevelopmentServer>> serversAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('DEVELOPMENT', Icons.code),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DevStatusCard.processes(processesAsync),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DevStatusCard.servers(serversAsync),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryRed),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _LoadingCardRow extends StatelessWidget {
  final int count;

  const _LoadingCardRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: index == count - 1 ? 0 : 12),
          child: const _LoadingCard(),
        ),
      )),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ErrorCardRow extends StatelessWidget {
  final String error;

  const _ErrorCardRow({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorRed),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Failed to load: $error',
                style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}


