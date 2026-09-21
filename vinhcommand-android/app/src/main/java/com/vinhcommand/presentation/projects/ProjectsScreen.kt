package com.vinhcommand.presentation.projects

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun ProjectsScreen(
    onProjectClick: (String) -> Unit,
    onNavigateToTasks: () -> Unit,
    onNavigateToHome: () -> Unit,
    viewModel: ProjectsViewModel = hiltViewModel()
) {
    Text("Projects Screen Placeholder")
}

@Composable
fun ProjectDetailScreen(
    projectId: String,
    onNavigateBack: () -> Unit,
    onNavigateToGit: () -> Unit,
    onNavigateToFiles: () -> Unit,
    onNavigateToTerminal: () -> Unit,
    onNavigateToPreview: () -> Unit,
    viewModel: ProjectsViewModel = hiltViewModel()
) {
    Text("Project Detail Screen Placeholder: $projectId")
}
