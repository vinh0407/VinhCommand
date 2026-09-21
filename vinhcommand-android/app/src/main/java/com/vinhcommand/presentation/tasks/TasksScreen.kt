package com.vinhcommand.presentation.tasks

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun TasksScreen(
    onTaskClick: (String) -> Unit,
    onNewTask: () -> Unit,
    onNavigateToHome: () -> Unit,
    viewModel: TasksViewModel = hiltViewModel()
) {
    Text("Tasks Screen Placeholder")
}

@Composable
fun TaskDetailScreen(
    taskId: String,
    onNavigateBack: () -> Unit,
    viewModel: TasksViewModel = hiltViewModel()
) {
    Text("Task Detail Screen Placeholder: $taskId")
}

@Composable
fun NewTaskScreen(
    onNavigateBack: () -> Unit,
    onTaskCreated: (String) -> Unit,
    viewModel: TasksViewModel = hiltViewModel()
) {
    Text("New Task Screen Placeholder")
}
