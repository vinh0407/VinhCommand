package com.vinhcommand.presentation.terminal

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun TerminalScreen(onNavigateBack: () -> Unit, viewModel: TerminalViewModel = hiltViewModel()) { Text("Terminal Screen Placeholder") }