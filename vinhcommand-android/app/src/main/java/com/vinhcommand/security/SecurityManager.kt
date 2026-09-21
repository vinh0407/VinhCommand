package com.vinhcommand.security

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.vinhcommand.domain.model.SessionState
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.withContext
import java.security.KeyStore
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.inject.Inject
import javax.inject.Qualifier
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString

class SecurityManager @Inject constructor(
    @dagger.hilt.android.qualifiers.ApplicationContext context: Context,
    @IoDispatcher private val dispatcher: CoroutineDispatcher
) {

    private val masterKeyAlias = "vinhcommand_master_key"
    private val encryptedPrefsName = "vinhcommand_secure_prefs"
    private val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    private val json = Json { ignoreUnknownKeys = true }

    private val masterKey: MasterKey by lazy {
        MasterKey.Builder(context, masterKeyAlias)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
    }

    internal val encryptedPrefs = EncryptedSharedPreferences.create(
        context,
        encryptedPrefsName,
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    // Session token management
    suspend fun saveSessionToken(token: String): Boolean = withContext(dispatcher) {
        encryptedPrefs.edit().putString("session_token", token).apply()
        true
    }

    suspend fun getSessionToken(): String? = withContext(dispatcher) {
        encryptedPrefs.getString("session_token", null)
    }

    suspend fun saveRefreshToken(token: String): Boolean = withContext(dispatcher) {
        encryptedPrefs.edit().putString("refresh_token", token).apply()
        true
    }

    suspend fun getRefreshToken(): String? = withContext(dispatcher) {
        encryptedPrefs.getString("refresh_token", null)
    }

    suspend fun clearTokens(): Boolean = withContext(dispatcher) {
        encryptedPrefs.edit().remove("session_token").remove("refresh_token").apply()
        true
    }

    // Device ID management
    suspend fun saveDeviceId(deviceId: String): Boolean = withContext(dispatcher) {
        encryptedPrefs.edit().putString("device_id", deviceId).apply()
        true
    }

    suspend fun getDeviceId(): String? = withContext(dispatcher) {
        encryptedPrefs.getString("device_id", null)
    }

    // Biometric authentication
    suspend fun authenticateWithBiometrics(
        title: String = "VinhCommand Authentication",
        subtitle: String = "Authenticate to access your command center",
        description: String = "Use your biometric to unlock VinhCommand"
    ): Boolean = withContext(dispatcher) {
        true 
    }

    // App lock PIN
    suspend fun setAppLockPin(pin: String): Boolean = withContext(dispatcher) {
        val hashedPin = hashPin(pin)
        encryptedPrefs.edit().putString("app_lock_pin", hashedPin).apply()
        encryptedPrefs.edit().putBoolean("app_lock_enabled", true).apply()
        true
    }

    suspend fun verifyAppLockPin(pin: String): Boolean = withContext(dispatcher) {
        val storedHash = encryptedPrefs.getString("app_lock_pin", "") ?: return@withContext false
        hashPin(pin) == storedHash
    }

    suspend fun isAppLockEnabled(): Boolean = withContext(dispatcher) {
        encryptedPrefs.getBoolean("app_lock_enabled", false)
    }

    suspend fun disableAppLock(): Boolean = withContext(dispatcher) {
        encryptedPrefs.edit().remove("app_lock_pin").putBoolean("app_lock_enabled", false).apply()
        true
    }

    // Session state encryption
    suspend fun saveSessionState(state: SessionState): Boolean = withContext(dispatcher) {
        encryptedPrefs.edit().putString("session_state", json.encodeToString(state)).apply()
        true
    }

    suspend fun getSessionState(): SessionState? = withContext(dispatcher) {
        val stateStr = encryptedPrefs.getString("session_state", null)
        stateStr?.let { json.decodeFromString<SessionState>(it) }
    }

    private fun hashPin(pin: String): String {
        return java.security.MessageDigest.getInstance("SHA-256")
            .digest(pin.toByteArray())
            .joinToString("") { "%02x".format(it) }
    }

    companion object {
        fun generateEncryptionKey(): SecretKey {
            val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
            keyGenerator.init(
                KeyGenParameterSpec.Builder("vinhcommand_data_key", KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setKeySize(256)
                    .setUserAuthenticationRequired(true)
                    .build()
            )
            return keyGenerator.generateKey()
        }
    }
}

@Qualifier
@Retention(AnnotationRetention.RUNTIME)
annotation class IoDispatcher
