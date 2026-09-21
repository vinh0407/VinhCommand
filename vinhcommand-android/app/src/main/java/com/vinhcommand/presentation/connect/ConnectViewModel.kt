package com.vinhcommand.presentation.connect

import okhttp3.HttpUrl.Companion.toHttpUrl
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel

import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.usecase.connection.*
import com.vinhcommand.presentation.common.BaseViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

@HiltViewModel
class ConnectViewModel @Inject constructor(
    private val connectToPcUseCase: ConnectToPcUseCase,
    private val disconnectFromPcUseCase: DisconnectFromPcUseCase,
    private val pairWithPcUseCase: PairWithPcUseCase,
    private val authenticateWithPcUseCase: AuthenticateWithPcUseCase,
    private val trustDeviceUseCase: TrustDeviceUseCase,
    private val observeConnectionStateUseCase: ObserveConnectionStateUseCase,
    private val observePcStateUseCase: ObservePcStateUseCase
) : BaseViewModel() {

    private val _desktopId = MutableStateFlow("")
    val desktopId = _desktopId.asStateFlow()

    private val _accessCode = MutableStateFlow("")
    val accessCode = _accessCode.asStateFlow()

    private val _isPairingMode = MutableStateFlow(false)
    val isPairingMode = _isPairingMode.asStateFlow()

    private val _pairingChallenge = MutableStateFlow<PairingChallenge?>(null)
    val pairingChallenge = _pairingChallenge.asStateFlow()

    private val _deviceId = MutableStateFlow("")
    val deviceId = _deviceId.asStateFlow()

    private val _deviceName = MutableStateFlow("Android Device")
    val deviceName = _deviceName.asStateFlow()

    val connectionState = observeConnectionStateUseCase()
    val pcState = observePcStateUseCase()

    fun setDesktopId(id: String) {
        _desktopId.value = id.replace(" ", "")
    }

    fun setAccessCode(code: String) {
        _accessCode.value = code
    }

    fun setPairingMode(enabled: Boolean) {
        _isPairingMode.value = enabled
    }

    fun setDeviceId(id: String) {
        _deviceId.value = id
    }

    fun setDeviceName(name: String) {
        _deviceName.value = name
    }

    private val _serverUrl = MutableStateFlow("http://192.168.1.20:8444")
    val serverUrl = _serverUrl.asStateFlow()
    fun setServerUrl(value: String) { _serverUrl.value = value }

    fun normalizeUrl(input: String): String {
        var clean = input.trim()
        if (clean.endsWith("/")) clean = clean.substring(0, clean.length - 1)
        if (!clean.startsWith("http://") && !clean.startsWith("https://")) {
            clean = "http://$clean"
        }
        val withoutScheme = clean.substringAfter("://")
        if (!withoutScheme.contains(":")) {
            clean = "$clean:8444"
        }
        return clean
    }

    fun handleQrCodeScanned(qrData: String) {
        val clean = qrData.trim()
        if (clean.isBlank()) return
        try {
            if (clean.startsWith("vinhcommand://connect", ignoreCase = true)) {
                val uri = android.net.Uri.parse(clean)
                val address = uri.getQueryParameter("address")
                val id = uri.getQueryParameter("id")
                val pin = uri.getQueryParameter("pin") ?: uri.getQueryParameter("code")
                if (!address.isNullOrBlank()) _serverUrl.value = address
                if (!id.isNullOrBlank()) _desktopId.value = id
                if (!pin.isNullOrBlank()) _accessCode.value = pin
                connect()
            } else if (clean.startsWith("http://", ignoreCase = true) || clean.startsWith("https://", ignoreCase = true)) {
                val uri = android.net.Uri.parse(clean)
                val address = if (uri.port > 0) "${uri.scheme}://${uri.host}:${uri.port}" else "${uri.scheme}://${uri.host}:8444"
                _serverUrl.value = address
                val id = uri.getQueryParameter("id")
                val pin = uri.getQueryParameter("pin") ?: uri.getQueryParameter("code")
                if (!id.isNullOrBlank()) _desktopId.value = id
                if (!pin.isNullOrBlank()) _accessCode.value = pin
                if (!id.isNullOrBlank() && !pin.isNullOrBlank()) {
                    connect()
                }
            } else if (clean.startsWith("{") && clean.endsWith("}")) {
                val obj = org.json.JSONObject(clean)
                val address = obj.optString("address", obj.optString("url", ""))
                val id = obj.optString("id", obj.optString("desktopId", ""))
                val pin = obj.optString("pin", obj.optString("code", ""))
                if (address.isNotBlank()) _serverUrl.value = address
                if (id.isNotBlank()) _desktopId.value = id
                if (pin.isNotBlank()) _accessCode.value = pin
                if (id.isNotBlank() && pin.isNotBlank()) {
                    connect()
                }
            } else {
                _serverUrl.value = normalizeUrl(clean)
            }
        } catch (e: Exception) {
            setState(UiState.Error("Không thể đọc mã QR: ${e.message}"))
        }
    }

    fun connect() {
        val rawDesktopId = _desktopId.value.replace(" ", "").trim()
        val rawAccessCode = _accessCode.value.replace(" ", "").trim()
        
        if (rawDesktopId.isBlank() || rawAccessCode.isBlank()) {
            setState(UiState.Error("Vui lòng nhập Desktop ID và Mã PIN kết nối"))
            return
        }

        setState(UiState.Loading("Đang kết nối tới máy tính..."))
        
        launch {
            val normalized = normalizeUrl(_serverUrl.value)
            val endpoint = try {
                normalized.toHttpUrl()
            } catch(e: Exception) {
                setState(UiState.Error("Địa chỉ máy tính không hợp lệ: $normalized (Ví dụ: http://192.168.1.20:8444)"))
                return@launch
            }

            val config = ConnectionConfig(
                desktopId = rawDesktopId,
                host = endpoint.host, 
                port = endpoint.port,
                useHttps = endpoint.isHttps,
                accessCode = rawAccessCode
            )
            
            val result = connectToPcUseCase(config)
            result.onSuccess { authResponse ->
                if (authResponse.success) {
                    setState(UiState.Success(authResponse))
                } else {
                    setState(UiState.Error(authResponse.error ?: "Kết nối thất bại. Kiểm tra lại Desktop ID và PIN."))
                }
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Không thể kết nối tới máy tính. Hãy đảm bảo Desktop và Mobile cùng chung Wi-Fi và Desktop đã bật LAN Connection."))
            }
        }
    }

    fun pair() {
        val desktopId = _desktopId.value
        if (desktopId.isBlank()) {
            setState(UiState.Error("Please enter Desktop ID"))
            return
        }

        setState(UiState.Loading("Pairing..."))
        
        launch {
            val request = PairingRequest(
                desktopId = desktopId,
                deviceName = _deviceName.value,
                appVersion = "1.0.0"
            )
            
            val result = pairWithPcUseCase(request)
            result.onSuccess { challenge ->
                _pairingChallenge.value = challenge
                _isPairingMode.value = true
                setState(UiState.Success(challenge))
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Pairing failed"))
            }
        }
    }

    fun authenticate() {
        val challenge = _pairingChallenge.value ?: return
        val accessCode = _accessCode.value
        
        if (accessCode.isBlank()) {
            setState(UiState.Error("Please enter access code"))
            return
        }

        setState(UiState.Loading("Authenticating..."))
        
        launch {
            val request = AuthRequest(
                desktopId = challenge.desktopId,
                accessCode = accessCode,
                deviceId = _deviceId.value,
                deviceName = _deviceName.value
            )
            
            val result = authenticateWithPcUseCase(request)
            result.onSuccess { authResponse ->
                if (authResponse.success) {
                    setState(UiState.Success(authResponse))
                } else {
                    setState(UiState.Error(authResponse.error ?: "Authentication failed"))
                }
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Authentication failed"))
            }
        }
    }

    fun trustDevice(trust: Boolean) {
        launch {
            val request = DeviceTrustRequest(
                deviceId = _deviceId.value,
                trust = trust,
                sessionToken = ""
            )
            
            val result = trustDeviceUseCase(request)
            result.onSuccess {
                setState(UiState.Success(Unit))
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to set trust"))
            }
        }
    }

    fun disconnect() {
        launch {
            disconnectFromPcUseCase(Unit)
            _desktopId.value = ""
            _accessCode.value = ""
            _isPairingMode.value = false
            _pairingChallenge.value = null
            setState(UiState.Idle)
        }
    }

    fun formatDesktopId(input: String): String {
        val clean = input.replace("\\D".toRegex(), "")
        if (clean.length <= 9) {
            return clean.chunked(3).joinToString(" ")
        }
        return clean.take(9).chunked(3).joinToString(" ")
    }

    fun validateDesktopId(id: String): Boolean {
        val clean = id.replace("\\s+".toRegex(), "")
        return clean.length == 9 && clean.all { it.isDigit() }
    }

    fun validateAccessCode(code: String): Boolean {
        return code.length >= 6
    }
}
