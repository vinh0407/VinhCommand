package com.vinhcommand.presentation.common

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.vinhcommand.presentation.connect.ConnectScreen
import com.vinhcommand.presentation.home.CompanionScreen

@Composable
fun AppNavHost() {
    val navController = rememberNavController()
    NavHost(navController, startDestination = "connect") {
        composable("connect") {
            ConnectScreen(onNavigateToHome = { navController.navigate("home") { launchSingleTop = true } })
        }
        composable("home") {
            CompanionScreen(onReconnect = { navController.popBackStack("connect", false) })
        }
    }
}
