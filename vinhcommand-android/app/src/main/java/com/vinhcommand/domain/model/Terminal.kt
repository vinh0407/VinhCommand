package com.vinhcommand.domain.model

import androidx.annotation.Keep
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Keep
@Serializable
data class TerminalSession(
    val id: String,
    val shellName: ShellType,
    val cwd: String,
    val history: List<String>,
    val logs: List<String>
)

@Keep
@Serializable
enum class ShellType {
    @SerialName("PowerShell") POWERSHELL,
    @SerialName("CMD") CMD,
    @SerialName("Git Bash") GIT_BASH,
    @SerialName("WSL") WSL,
    @SerialName("Bash") BASH,
    @SerialName("Zsh") ZSH
}

@Keep
@Serializable
data class TerminalCommand(
    val sessionId: String,
    val command: String,
    val timestamp: String
)

@Keep
@Serializable
data class TerminalOutput(
    val sessionId: String,
    val output: String,
    val timestamp: String,
    val isError: Boolean = false
)

@Keep
@Serializable
data class TerminalResize(
    val sessionId: String,
    val cols: Int,
    val rows: Int
)
