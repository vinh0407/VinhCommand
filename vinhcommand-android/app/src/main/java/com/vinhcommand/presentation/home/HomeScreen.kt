package com.vinhcommand.presentation.home

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun HomeScreen(
    onNavigateToProjects: () -> Unit,
    onNavigateToTasks: () -> Unit,
    onNavigateToAgents: () -> Unit,
    onNavigateToTerminal: () -> Unit,
    onNavigateToFiles: () -> Unit,
    onNavigateToGit: () -> Unit,
    onNavigateToProcesses: () -> Unit,
    onNavigateToServers: () -> Unit,
    onNavigateToPreview: () -> Unit,
    onNavigateToScreen: () -> Unit,
    onNavigateToSecurity: () -> Unit,
    onNavigateToSettings: () -> Unit,
    viewModel: HomeViewModel = hiltViewModel()
) {
    Text("Home Screen Placeholder")
}
