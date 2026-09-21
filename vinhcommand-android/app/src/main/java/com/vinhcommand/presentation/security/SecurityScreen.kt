package com.vinhcommand.presentation.security

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun SecurityScreen(onNavigateBack: () -> Unit, viewModel: SecurityViewModel = hiltViewModel()) { Text("Security Screen Placeholder") }