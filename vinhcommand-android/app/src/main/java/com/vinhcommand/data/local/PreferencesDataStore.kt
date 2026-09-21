package com.vinhcommand.data.local

import android.content.Context
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.rxjava3.RxPreferenceDataStoreBuilder
import androidx.datastore.rxjava3.RxDataStore
import io.reactivex.rxjava3.core.Flowable
import io.reactivex.rxjava3.core.Single
import javax.inject.Inject
import javax.inject.Singleton
import dagger.hilt.android.qualifiers.ApplicationContext

@Singleton
class PreferencesDataStore @Inject constructor(
    @ApplicationContext context: Context
) {

    private val dataStore: RxDataStore<Preferences> = RxPreferenceDataStoreBuilder(context, "vinhcommand_prefs").build()

    // Keys
    private val KEY_THEME = stringPreferencesKey("theme")
    private val KEY_LOCK_TIMEOUT = longPreferencesKey("lock_timeout")
    private val KEY_AUTO_CONNECT = booleanPreferencesKey("auto_connect")
    private val KEY_NOTIFICATIONS_ENABLED = booleanPreferencesKey("notifications_enabled")
    private val KEY_BIOMETRIC_ENABLED = booleanPreferencesKey("biometric_enabled")
    private val KEY_REMOTE_CONTROL_ENABLED = booleanPreferencesKey("remote_control_enabled")
    private val KEY_COMMAND_APPROVAL_REQUIRED = booleanPreferencesKey("command_approval_required")
    private val KEY_TERMINAL_SHELL = stringPreferencesKey("terminal_shell")
    private val KEY_TERMINAL_FONT_SIZE = floatPreferencesKey("terminal_font_size")
    private val KEY_EDITOR_FONT_SIZE = floatPreferencesKey("editor_font_size")
    private val KEY_EDITOR_TAB_SIZE = intPreferencesKey("editor_tab_size")
    private val KEY_SCREEN_STREAM_QUALITY = intPreferencesKey("screen_stream_quality")
    private val KEY_SCREEN_STREAM_FPS = intPreferencesKey("screen_stream_fps")
    private val KEY_AUTO_SAVE_FILES = booleanPreferencesKey("auto_save_files")
    private val KEY_SHOW_LINE_NUMBERS = booleanPreferencesKey("show_line_numbers")
    private val KEY_WORD_WRAP = booleanPreferencesKey("word_wrap")
    private val KEY_LANGUAGE = stringPreferencesKey("language")
    private val KEY_LAST_DESKTOP_ID = stringPreferencesKey("last_desktop_id")
    private val KEY_LAST_HOST = stringPreferencesKey("last_host")
    private val KEY_LAST_PORT = intPreferencesKey("last_port")
    private val KEY_USE_HTTPS = booleanPreferencesKey("use_https")
    private val KEY_USE_WSS = booleanPreferencesKey("use_wss")

    // Theme
    val theme: Flowable<String> = dataStore.data()
        .map { it[KEY_THEME] ?: "DARK" }

    suspend fun setTheme(theme: String) = dataStore.updateDataAsync { 
        val mutable = it.toMutablePreferences()
        mutable[KEY_THEME] = theme 
        Single.just(mutable.toPreferences())
    }

    // Lock timeout
    val lockTimeout: Flowable<Long> = dataStore.data()
        .map { it[KEY_LOCK_TIMEOUT] ?: 300_000L }

    suspend fun setLockTimeout(timeout: Long) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_LOCK_TIMEOUT] = timeout
        Single.just(mutable.toPreferences())
    }

    // Auto connect
    val autoConnect: Flowable<Boolean> = dataStore.data()
        .map { it[KEY_AUTO_CONNECT] ?: false }

    suspend fun setAutoConnect(enabled: Boolean) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_AUTO_CONNECT] = enabled
        Single.just(mutable.toPreferences())
    }

    // Notifications
    val notificationsEnabled: Flowable<Boolean> = dataStore.data()
        .map { it[KEY_NOTIFICATIONS_ENABLED] ?: true }

    suspend fun setNotificationsEnabled(enabled: Boolean) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_NOTIFICATIONS_ENABLED] = enabled
        Single.just(mutable.toPreferences())
    }

    // Biometric
    val biometricEnabled: Flowable<Boolean> = dataStore.data()
        .map { it[KEY_BIOMETRIC_ENABLED] ?: false }

    suspend fun setBiometricEnabled(enabled: Boolean) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_BIOMETRIC_ENABLED] = enabled
        Single.just(mutable.toPreferences())
    }

    // Remote control
    val remoteControlEnabled: Flowable<Boolean> = dataStore.data()
        .map { it[KEY_REMOTE_CONTROL_ENABLED] ?: false }

    suspend fun setRemoteControlEnabled(enabled: Boolean) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_REMOTE_CONTROL_ENABLED] = enabled
        Single.just(mutable.toPreferences())
    }

    // Command approval
    val commandApprovalRequired: Flowable<Boolean> = dataStore.data()
        .map { it[KEY_COMMAND_APPROVAL_REQUIRED] ?: true }

    suspend fun setCommandApprovalRequired(required: Boolean) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_COMMAND_APPROVAL_REQUIRED] = required
        Single.just(mutable.toPreferences())
    }

    // Terminal settings
    val terminalShell: Flowable<String> = dataStore.data()
        .map { it[KEY_TERMINAL_SHELL] ?: "PowerShell" }

    suspend fun setTerminalShell(shell: String) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_TERMINAL_SHELL] = shell
        Single.just(mutable.toPreferences())
    }

    val terminalFontSize: Flowable<Float> = dataStore.data()
        .map { it[KEY_TERMINAL_FONT_SIZE] ?: 14f }

    suspend fun setTerminalFontSize(size: Float) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_TERMINAL_FONT_SIZE] = size
        Single.just(mutable.toPreferences())
    }

    // Editor settings
    val editorFontSize: Flowable<Float> = dataStore.data()
        .map { it[KEY_EDITOR_FONT_SIZE] ?: 14f }

    suspend fun setEditorFontSize(size: Float) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_EDITOR_FONT_SIZE] = size
        Single.just(mutable.toPreferences())
    }

    val editorTabSize: Flowable<Int> = dataStore.data()
        .map { it[KEY_EDITOR_TAB_SIZE] ?: 4 }

    suspend fun setEditorTabSize(size: Int) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_EDITOR_TAB_SIZE] = size
        Single.just(mutable.toPreferences())
    }

    // Screen stream settings
    val screenStreamQuality: Flowable<Int> = dataStore.data()
        .map { it[KEY_SCREEN_STREAM_QUALITY] ?: 70 }

    suspend fun setScreenStreamQuality(quality: Int) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_SCREEN_STREAM_QUALITY] = quality
        Single.just(mutable.toPreferences())
    }

    val screenStreamFps: Flowable<Int> = dataStore.data()
        .map { it[KEY_SCREEN_STREAM_FPS] ?: 15 }

    suspend fun setScreenStreamFps(fps: Int) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_SCREEN_STREAM_FPS] = fps
        Single.just(mutable.toPreferences())
    }

    // File settings
    val autoSaveFiles: Flowable<Boolean> = dataStore.data()
        .map { it[KEY_AUTO_SAVE_FILES] ?: true }

    suspend fun setAutoSaveFiles(enabled: Boolean) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_AUTO_SAVE_FILES] = enabled
        Single.just(mutable.toPreferences())
    }

    val showLineNumbers: Flowable<Boolean> = dataStore.data()
        .map { it[KEY_SHOW_LINE_NUMBERS] ?: true }

    suspend fun setShowLineNumbers(enabled: Boolean) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_SHOW_LINE_NUMBERS] = enabled
        Single.just(mutable.toPreferences())
    }

    val wordWrap: Flowable<Boolean> = dataStore.data()
        .map { it[KEY_WORD_WRAP] ?: false }

    suspend fun setWordWrap(enabled: Boolean) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_WORD_WRAP] = enabled
        Single.just(mutable.toPreferences())
    }

    // Language
    val language: Flowable<String> = dataStore.data()
        .map { it[KEY_LANGUAGE] ?: "en" }

    suspend fun setLanguage(lang: String) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_LANGUAGE] = lang
        Single.just(mutable.toPreferences())
    }

    // Connection settings
    val lastDesktopId: Flowable<String> = dataStore.data()
        .map { it[KEY_LAST_DESKTOP_ID] ?: "" }

    suspend fun setLastDesktopId(id: String?) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_LAST_DESKTOP_ID] = id ?: ""
        Single.just(mutable.toPreferences())
    }

    val lastHost: Flowable<String> = dataStore.data()
        .map { it[KEY_LAST_HOST] ?: "" }

    suspend fun setLastHost(host: String?) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_LAST_HOST] = host ?: ""
        Single.just(mutable.toPreferences())
    }

    val lastPort: Flowable<Int> = dataStore.data()
        .map { it[KEY_LAST_PORT] ?: 8444 }

    suspend fun setLastPort(port: Int) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_LAST_PORT] = port
        Single.just(mutable.toPreferences())
    }

    val useHttps: Flowable<Boolean> = dataStore.data()
        .map { it[KEY_USE_HTTPS] ?: true }

    suspend fun setUseHttps(enabled: Boolean) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_USE_HTTPS] = enabled
        Single.just(mutable.toPreferences())
    }

    val useWss: Flowable<Boolean> = dataStore.data()
        .map { it[KEY_USE_WSS] ?: true }

    suspend fun setUseWss(enabled: Boolean) = dataStore.updateDataAsync {
        val mutable = it.toMutablePreferences()
        mutable[KEY_USE_WSS] = enabled
        Single.just(mutable.toPreferences())
    }

    // Clear all
    suspend fun clearAll() = dataStore.updateDataAsync { 
        val mutable = it.toMutablePreferences()
        mutable.clear()
        Single.just(mutable.toPreferences())
    }
}
