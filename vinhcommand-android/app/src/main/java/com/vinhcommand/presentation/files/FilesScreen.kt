package com.vinhcommand.presentation.files

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun FilesScreen(onNavigateBack: () -> Unit, viewModel: FilesViewModel = hiltViewModel()) { Text("Files Screen Placeholder") }