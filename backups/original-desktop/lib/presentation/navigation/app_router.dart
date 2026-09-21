import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:async/async.dart';
import 'package:vinhcommand_desktop/presentation/vinhcommand_presentation.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/agents',
            builder: (context, state) => const AgentsScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectsScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/terminal',
            builder: (context, state) => const TerminalScreen(),
          ),
          GoRoute(
            path: '/files',
            builder: (context, state) => const FilesScreen(),
          ),
          GoRoute(
            path: '/git',
            builder: (context, state) => const GitScreen(),
          ),
          GoRoute(
            path: '/processes',
            builder: (context, state) => const ProcessesScreen(),
          ),
          GoRoute(
            path: '/servers',
            builder: (context, state) => const ServersScreen(),
          ),
          GoRoute(
            path: '/preview',
            builder: (context, state) => const PreviewScreen(),
          ),
          GoRoute(
            path: '/screen',
            builder: (context, state) => const ScreenScreen(),
          ),
          GoRoute(
            path: '/automation',
            builder: (context, state) => const AutomationScreen(),
          ),
          GoRoute(
            path: '/security',
            builder: (context, state) => const SecurityScreen(),
          ),
          GoRoute(
            path: '/diagnostics',
            builder: (context, state) => const DiagnosticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  bool _sidebarCollapsed = false;
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    NavigationItem(
      icon: Icons.smart_toy_outlined,
      selectedIcon: Icons.smart_toy,
      label: 'Agents',
      route: '/agents',
    ),
    NavigationItem(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      label: 'Projects',
      route: '/projects',
    ),
    NavigationItem(
      icon: Icons.task_alt_outlined,
      selectedIcon: Icons.task_alt,
      label: 'Tasks',
      route: '/tasks',
    ),
    NavigationItem(
      icon: Icons.terminal_outlined,
      selectedIcon: Icons.terminal,
      label: 'Terminal',
      route: '/terminal',
    ),
    NavigationItem(
      icon: Icons.insert_drive_file_outlined,
      selectedIcon: Icons.insert_drive_file,
      label: 'Files',
      route: '/files',
    ),
    NavigationItem(
      icon: Icons.source_outlined,
      selectedIcon: Icons.source,
      label: 'Git',
      route: '/git',
    ),
    NavigationItem(
      icon: Icons.memory_outlined,
      selectedIcon: Icons.memory,
      label: 'Processes',
      route: '/processes',
    ),
    NavigationItem(
      icon: Icons.dns_outlined,
      selectedIcon: Icons.dns,
      label: 'Servers',
      route: '/servers',
    ),
    NavigationItem(
      icon: Icons.preview_outlined,
      selectedIcon: Icons.preview,
      label: 'Preview',
      route: '/preview',
    ),
    NavigationItem(
      icon: Icons.monitor_outlined,
      selectedIcon: Icons.monitor,
      label: 'Screen',
      route: '/screen',
    ),
    NavigationItem(
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
      label: 'Automation',
      route: '/automation',
    ),
    NavigationItem(
      icon: Icons.security_outlined,
      selectedIcon: Icons.security,
      label: 'Security',
      route: '/security',
    ),
    NavigationItem(
      icon: Icons.bug_report_outlined,
      selectedIcon: Icons.bug_report,
      label: 'Diagnostics',
      route: '/diagnostics',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _sidebarCollapsed ? 56 : 240,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _getCurrentRoute().startsWith(item.route);
                return _buildNavItem(item, isSelected);
              },
            ),
          ),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  String _getCurrentRoute() {
    // This would come from GoRouter state
    return '/dashboard';
  }

  Widget _buildSidebarHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (!_sidebarCollapsed) ...[
            const Icon(Icons.terminal, color: AppTheme.primaryRed, size: 28),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'VINHCOMMAND',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'AI AGENT COMMAND CENTER',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
          IconButton(
            icon: Icon(
              _sidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
              size: 20,
            ),
            onPressed: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            tooltip: _sidebarCollapsed ? 'Expand' : 'Collapse',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(NavigationItem item, bool isSelected) {
    if (_sidebarCollapsed) {
      return Tooltip(
        message: item.label,
        child: InkWell(
          onTap: () => context.go(item.route),
          child: Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppTheme.primaryRed.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: isSelected
                  ? Border.all(color: AppTheme.primaryRed, width: 1)
                  : null,
            ),
            child: Center(
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: 22,
                color: isSelected ? AppTheme.primaryRed : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => context.go(item.route),
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryRed.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isSelected
              ? Border.all(color: AppTheme.primaryRed, width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.icon,
              size: 20,
              color: isSelected ? AppTheme.primaryRed : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 3,
                height: 20,
                color: AppTheme.primaryRed,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: _sidebarCollapsed
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text(
                  'SHORTCUTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                _buildShortcut('Ctrl+K', 'Command Palette'),
                _buildShortcut('Ctrl+P', 'File Search'),
                _buildShortcut('Ctrl+Shift+F', 'Global Search'),
                _buildShortcut('Ctrl+`', 'Terminal'),
                _buildShortcut('Ctrl+B', 'Toggle Sidebar'),
              ],
            ),
    );
  }

  Widget _buildShortcut(String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              key,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SearchField(),
          const Spacer(),
          _buildSystemStatus(),
          const SizedBox(width: 16),
          _buildNotificationButton(),
          const SizedBox(width: 8),
          _buildUserMenu(),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Row(
      children: [
        _StatusIndicator(
          label: 'CPU',
          value: '12%',
          color: AppTheme.successGreen,
        ),
        const SizedBox(width: 16),
        _StatusIndicator(
          label: 'RAM',
          value: '4.2/16 GB',
          color: AppTheme.warningOrange,
        ),
        const SizedBox(width: 16),
        _StatusIndicator(
          label: 'GPU',
          value: '23%',
          color: AppTheme.infoBlue,
        ),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 22),
          onPressed: () {},
          tooltip: 'Notifications',
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.errorRed,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMenu() {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: AppTheme.primaryRed,
        child: const Text(
          'VC',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'profile', child: Text('Profile')),
        const PopupMenuItem(value: 'settings', child: Text('Settings')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'logout', child: Text('Logout')),
      ],
      onSelected: (value) {
        if (value == 'settings') context.go('/settings');
      },
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}

class SearchField extends StatelessWidget {
  const SearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search... (Ctrl+K)',
          prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
          suffixIcon: IconButton(
            icon: const Icon(Icons.keyboard_command_key, size: 18, color: AppTheme.textMuted),
            onPressed: () {},
            tooltip: 'Command Palette (Ctrl+K)',
          ),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusIndicator({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
