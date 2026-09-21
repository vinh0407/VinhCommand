import { Outlet, NavLink, useLocation } from 'react-router-dom';
import { useState } from 'react';
import { FolderGit, Terminal, Bot, Settings, ChevronLeft, ChevronRight, Menu, X } from 'lucide-react';
import { clsx } from '@vinhcommand/shared';
import { useTheme } from '../context/ThemeContext';

const navigation = [
  { name: 'Projects', href: '/projects', icon: FolderGit },
  { name: 'Editor', href: '/editor', icon: Terminal },
  { name: 'Terminal', href: '/terminal', icon: Terminal },
  { name: 'AI Agents', href: '/ai', icon: Bot },
  { name: 'Settings', href: '/settings', icon: Settings },
];

export function Layout() {
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const { resolvedTheme, toggleTheme } = useTheme();

  return (
    <div className="flex h-screen w-screen overflow-hidden">
      {/* Sidebar */}
      <aside
        className={clsx(
          'fixed inset-y-0 left-0 z-40 transition-all duration-300 ease-in-out bg-white dark:bg-gray-900 border-r border-gray-200 dark:border-gray-800 flex flex-col',
          sidebarOpen ? 'w-64' : 'w-16',
          mobileMenuOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
        )}
      >
        {/* Logo */}
        <div className={clsx('flex items-center justify-between h-16 px-4 border-b border-gray-200 dark:border-gray-800', sidebarOpen ? '' : 'justify-center')}>
          {sidebarOpen && (
            <span className="flex items-center gap-2 text-xl font-bold text-gray-900 dark:text-white">
              <span className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center">
                <Menu className="w-5 h-5 text-white" />
              </span>
              VinhCommand
            </span>
          )}
          {!sidebarOpen && (
            <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center">
              <Menu className="w-5 h-5 text-white" />
            </div>
          )}
          <button
            className={clsx('p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors', sidebarOpen ? '' : 'hidden lg:block')}
            onClick={() => setSidebarOpen(!sidebarOpen)}
            aria-label="Toggle sidebar"
          >
            {sidebarOpen ? <ChevronLeft className="w-5 h-5 text-gray-500" /> : <ChevronRight className="w-5 h-5 text-gray-500" />}
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto" role="navigation" aria-label="Main navigation">
          {navigation.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname.startsWith(item.href);
            return (
              <NavLink
                key={item.name}
                to={item.href}
                className={({ isActive: active }) => clsx(
                  'flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all duration-200',
                  'hover:bg-gray-100 dark:hover:bg-gray-800',
                  active
                    ? 'bg-primary/10 text-primary dark:bg-primary/20'
                    : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white',
                  !sidebarOpen && 'justify-center px-2'
                )}
                title={sidebarOpen ? undefined : item.name}
                aria-label={item.name}
              >
                <Icon className="w-5 h-5 flex-shrink-0" aria-hidden="true" />
                {sidebarOpen && <span className="font-medium truncate">{item.name}</span>}
              </NavLink>
            );
          })}
        </nav>

        {/* Bottom section */}
        <div className={clsx('p-3 border-t border-gray-200 dark:border-gray-800', !sidebarOpen && 'hidden')}>
          <div className="flex items-center gap-3 px-3 py-2.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors cursor-pointer" onClick={toggleTheme}>
            <span className="w-5 h-5 text-gray-500">
              {resolvedTheme === 'dark' ? '🌙' : '☀️'}
            </span>
            <span className="text-sm font-medium text-gray-600 dark:text-gray-400">
              {resolvedTheme === 'dark' ? 'Dark Mode' : 'Light Mode'}
            </span>
          </div>
        </div>
      </aside>

      {/* Mobile overlay */}
      {mobileMenuOpen && (
        <div
          className="fixed inset-0 z-30 bg-black/50 lg:hidden"
          onClick={() => setMobileMenuOpen(false)}
          aria-hidden="true"
        />
      )}

      {/* Main content */}
      <main
        className={clsx(
          'flex-1 flex flex-col overflow-hidden transition-all duration-300',
          sidebarOpen ? 'lg:ml-64' : 'lg:ml-16'
        )}
      >
        {/* Top bar */}
        <header className="h-12 px-4 flex items-center justify-between bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm border-b border-gray-200 dark:border-gray-800">
          <button
            className="lg:hidden p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800"
            onClick={() => setMobileMenuOpen(true)}
            aria-label="Open menu"
          >
            <Menu className="w-5 h-5 text-gray-600 dark:text-gray-400" />
          </button>
          <div className="flex-1 lg:hidden" />
          <div className="flex items-center gap-4">
            <button
              className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
              onClick={toggleTheme}
              aria-label="Toggle theme"
            >
              {resolvedTheme === 'dark' ? '🌙' : '☀️'}
            </button>
          </div>
        </header>

        {/* Content */}
        <div className="flex-1 overflow-auto p-6">
          <Outlet />
        </div>
      </main>
    </div>
  );
}