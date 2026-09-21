package com.vinhcommand.security

import android.app.Application
import android.os.SystemClock
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleObserver
import androidx.lifecycle.OnLifecycleEvent
import androidx.lifecycle.ProcessLifecycleOwner
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

class AppLockManager @Inject constructor(
    private val application: Application,
    private val securityManager: SecurityManager,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : LifecycleObserver {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val _isLocked = MutableStateFlow(false)
    val isLocked = _isLocked.asStateFlow()

    private val _lockTimeout = MutableStateFlow(300_000L) // 5 minutes default
    val lockTimeout = _lockTimeout.asStateFlow()

    private var lastActivityTime = SystemClock.elapsedRealtime()
    private var lockJob: Job? = null

    init {
        ProcessLifecycleOwner.get().lifecycle.addObserver(this)
        checkAndUpdateLockState()
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_START)
    fun onAppForeground() {
        lastActivityTime = SystemClock.elapsedRealtime()
        cancelLockJob()
        scope.launch {
            val enabled = securityManager.isAppLockEnabled()
            if (enabled) {
                checkAndUpdateLockState()
            }
        }
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_STOP)
    fun onAppBackground() {
        lastActivityTime = SystemClock.elapsedRealtime()
        scheduleLock()
    }

    fun onUserInteraction() {
        lastActivityTime = SystemClock.elapsedRealtime()
        cancelLockJob()
        if (_isLocked.value) {
            // Don't auto-unlock, require explicit unlock
        } else {
            scheduleLock()
        }
    }

    suspend fun unlockWithBiometrics(): Boolean {
        return securityManager.authenticateWithBiometrics().also { success ->
            if (success) {
                _isLocked.value = false
                cancelLockJob()
            }
        }
    }

    suspend fun unlockWithPin(pin: String): Boolean {
        return securityManager.verifyAppLockPin(pin).also { success ->
            if (success) {
                _isLocked.value = false
                cancelLockJob()
            }
        }
    }

    suspend fun setLockTimeout(timeoutMs: Long) {
        _lockTimeout.value = timeoutMs
        securityManager.encryptedPrefs.edit().putLong("lock_timeout", timeoutMs).apply()
        scheduleLock()
    }

    private fun checkAndUpdateLockState() {
        scope.launch(ioDispatcher) {
            val enabled = securityManager.isAppLockEnabled()
            if (enabled) {
                val elapsed = SystemClock.elapsedRealtime() - lastActivityTime
                val timeout = _lockTimeout.value
                if (elapsed >= timeout) {
                    _isLocked.value = true
                } else {
                    scheduleLock()
                }
            } else {
                _isLocked.value = false
            }
        }
    }

    private fun scheduleLock() {
        cancelLockJob()
        val timeout = _lockTimeout.value
        lockJob = scope.launch {
            delay(timeout)
            _isLocked.value = true
        }
    }

    private fun cancelLockJob() {
        lockJob?.cancel()
        lockJob = null
    }

    fun destroy() {
        scope.cancel()
        ProcessLifecycleOwner.get().lifecycle.removeObserver(this)
    }
}
