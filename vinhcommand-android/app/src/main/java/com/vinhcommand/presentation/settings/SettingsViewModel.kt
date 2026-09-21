package com.vinhcommand.presentation.settings

import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel


import com.vinhcommand.data.local.PreferencesDataStore
import com.vinhcommand.presentation.common.BaseViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val preferencesDataStore: PreferencesDataStore
) : BaseViewModel() {

    // Theme
    val theme = preferencesDataStore.theme
    fun setTheme(theme: String) = launch { preferencesDataStore.setTheme(theme) }

    // Lock timeout
    val lockTimeout = preferencesDataStore.lockTimeout
    fun setLockTimeout(timeout: Long) = launch { preferencesDataStore.setLockTimeout(timeout) }

    // Auto connect
    val autoConnect = preferencesDataStore.autoConnect
    fun setAutoConnect(enabled: Boolean) = launch { preferencesDataStore.setAutoConnect(enabled) }

    // Notifications
    val notificationsEnabled = preferencesDataStore.notificationsEnabled
    fun setNotificationsEnabled(enabled: Boolean) = launch { preferencesDataStore.setNotificationsEnabled(enabled) }

    // Biometric
    val biometricEnabled = preferencesDataStore.biometricEnabled
    fun setBiometricEnabled(enabled: Boolean) = launch { preferencesDataStore.setBiometricEnabled(enabled) }

    // Remote control
    val remoteControlEnabled = preferencesDataStore.remoteControlEnabled
    fun setRemoteControlEnabled(enabled: Boolean) = launch { preferencesDataStore.setRemoteControlEnabled(enabled) }

    // Command approval
    val commandApprovalRequired = preferencesDataStore.commandApprovalRequired
    fun setCommandApprovalRequired(required: Boolean) = launch { preferencesDataStore.setCommandApprovalRequired(required) }

    // Terminal settings
    val terminalShell = preferencesDataStore.terminalShell
    fun setTerminalShell(shell: String) = launch { preferencesDataStore.setTerminalShell(shell) }

    val terminalFontSize = preferencesDataStore.terminalFontSize
    fun setTerminalFontSize(size: Float) = launch { preferencesDataStore.setTerminalFontSize(size) }

    // Editor settings
    val editorFontSize = preferencesDataStore.editorFontSize
    fun setEditorFontSize(size: Float) = launch { preferencesDataStore.setEditorFontSize(size) }

    val editorTabSize = preferencesDataStore.editorTabSize
    fun setEditorTabSize(size: Int) = launch { preferencesDataStore.setEditorTabSize(size) }

    // Screen stream
    val screenStreamQuality = preferencesDataStore.screenStreamQuality
    fun setScreenStreamQuality(quality: Int) = launch { preferencesDataStore.setScreenStreamQuality(quality) }

    val screenStreamFps = preferencesDataStore.screenStreamFps
    fun setScreenStreamFps(fps: Int) = launch { preferencesDataStore.setScreenStreamFps(fps) }

    // File settings
    val autoSaveFiles = preferencesDataStore.autoSaveFiles
    fun setAutoSaveFiles(enabled: Boolean) = launch { preferencesDataStore.setAutoSaveFiles(enabled) }

    val showLineNumbers = preferencesDataStore.showLineNumbers
    fun setShowLineNumbers(enabled: Boolean) = launch { preferencesDataStore.setShowLineNumbers(enabled) }

    val wordWrap = preferencesDataStore.wordWrap
    fun setWordWrap(enabled: Boolean) = launch { preferencesDataStore.setWordWrap(enabled) }

    // Language
    val language = preferencesDataStore.language
    fun setLanguage(lang: String) = launch { preferencesDataStore.setLanguage(lang) }

    // Connection settings
    val lastDesktopId = preferencesDataStore.lastDesktopId
    val lastHost = preferencesDataStore.lastHost
    val lastPort = preferencesDataStore.lastPort
    val useHttps = preferencesDataStore.useHttps
    val useWss = preferencesDataStore.useWss

    fun clearAllSettings() = launch { preferencesDataStore.clearAll() }
}

