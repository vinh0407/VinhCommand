package com.vinhcommand.presentation.connect

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vinhcommand.presentation.common.BaseViewModel
import com.vinhcommand.domain.model.ConnectionState

@Composable
fun ConnectScreen(onNavigateToHome: () -> Unit, viewModel: ConnectViewModel = hiltViewModel()) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val server by viewModel.serverUrl.collectAsStateWithLifecycle()
    val desktop by viewModel.desktopId.collectAsStateWithLifecycle()
    val code by viewModel.accessCode.collectAsStateWithLifecycle()
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val connection by viewModel.connectionState.collectAsStateWithLifecycle()
    val loading = state is BaseViewModel.UiState.Loading

    var showQrDialog by remember { mutableStateOf(false) }
    var manualQrInput by remember { mutableStateOf("") }

    if (showQrDialog) {
        AlertDialog(
            onDismissRequest = { showQrDialog = false },
            title = { Text("Quét mã QR thêm thiết bị") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text(
                        "Mở ứng dụng VinhCommand trên máy tính, vào Cài đặt (Settings) -> Xem Mã QR để quét hoặc sao chép thông tin kết nối.",
                        style = MaterialTheme.typography.bodySmall
                    )
                    Button(
                        onClick = {
                            try {
                                val clipboard = context.getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
                                val item = clipboard.primaryClip?.getItemAt(0)?.text?.toString()
                                if (!item.isNullOrBlank()) {
                                    viewModel.handleQrCodeScanned(item)
                                    showQrDialog = false
                                    android.widget.Toast.makeText(context, "Đã đọc mã từ Clipboard!", android.widget.Toast.LENGTH_SHORT).show()
                                } else {
                                    android.widget.Toast.makeText(context, "Clipboard đang trống. Hãy sao chép mã QR từ Desktop.", android.widget.Toast.LENGTH_SHORT).show()
                                }
                            } catch (e: Exception) {
                                android.widget.Toast.makeText(context, "Lỗi đọc clipboard: ${e.message}", android.widget.Toast.LENGTH_SHORT).show()
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                    ) {
                        Text("Dán mã QR từ Clipboard")
                    }

                    OutlinedTextField(
                        value = manualQrInput,
                        onValueChange = { manualQrInput = it },
                        label = { Text("Hoặc dán chuỗi mã QR / URL") },
                        placeholder = { Text("vinhcommand://connect?address=... hoặc JSON") },
                        modifier = Modifier.fillMaxWidth(),
                        maxLines = 3
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (manualQrInput.isNotBlank()) {
                            viewModel.handleQrCodeScanned(manualQrInput)
                            showQrDialog = false
                        }
                    },
                    enabled = manualQrInput.isNotBlank()
                ) {
                    Text("Kết nối từ mã này")
                }
            },
            dismissButton = {
                TextButton(onClick = { showQrDialog = false }) {
                    Text("Đóng")
                }
            }
        )
    }

    Surface(modifier = Modifier.fillMaxSize()) {
        Column(
            Modifier
                .fillMaxSize()
                .safeDrawingPadding()
                .verticalScroll(rememberScrollState())
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text("VinhCommand Companion", style = MaterialTheme.typography.headlineLarge)
            Text("Kết nối với Máy tính Desktop", style = MaterialTheme.typography.titleLarge)
            Text(
                "Đảm bảo điện thoại và máy tính cùng kết nối chung một mạng Wi-Fi. Mở ứng dụng trên máy tính -> Màn hình Cài đặt (Settings) hoặc Dashboard để xem địa chỉ IP, Desktop ID và Mã PIN.",
                style = MaterialTheme.typography.bodyMedium
            )

            Button(
                onClick = { showQrDialog = true },
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Quét mã QR để thêm thiết bị")
            }

            OutlinedTextField(
                value = server,
                onValueChange = viewModel::setServerUrl,
                label = { Text("Địa chỉ máy tính (Server URL)") },
                placeholder = { Text("http://192.168.1.20:8444") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
                modifier = Modifier.fillMaxWidth(),
                enabled = !loading
            )

            OutlinedTextField(
                value = desktop,
                onValueChange = viewModel::setDesktopId,
                label = { Text("Desktop ID") },
                placeholder = { Text("Nhập 9 số Desktop ID") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                enabled = !loading
            )

            OutlinedTextField(
                value = code,
                onValueChange = viewModel::setAccessCode,
                label = { Text("Mã PIN kết nối (Pairing PIN)") },
                placeholder = { Text("Nhập 6 số mã PIN") },
                visualTransformation = PasswordVisualTransformation(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                modifier = Modifier.fillMaxWidth(),
                enabled = !loading
            )

            if (state is BaseViewModel.UiState.Error) {
                Card(
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        (state as BaseViewModel.UiState.Error).message,
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier.padding(12.dp),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }

            if (loading) {
                LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
            }

            Button(
                onClick = viewModel::connect,
                enabled = !loading && desktop.isNotBlank() && code.isNotBlank(),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(if (loading) "Đang kết nối..." else "Kết nối ngay")
            }

            if (connection == ConnectionState.CONNECTED) {
                Button(
                    onClick = onNavigateToHome,
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Đã kết nối — Mở Trung tâm Điều khiển")
                }
                OutlinedButton(
                    onClick = viewModel::disconnect,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Ngắt kết nối")
                }
            }
        }
    }
}

