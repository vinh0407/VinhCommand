package com.vinhcommand.presentation.agents

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vinhcommand.domain.model.AIAgent
import com.vinhcommand.domain.model.AgentStatus

@Composable
fun AgentsScreen(
    onNavigateBack: () -> Unit,
    viewModel: AgentsViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val agents by viewModel.agents.collectAsStateWithLifecycle(initialValue = emptyList())
    val selectedId by viewModel.selectedAgentId.collectAsStateWithLifecycle()
    val agentDetail by viewModel.agentDetail.collectAsStateWithLifecycle()
    val promptText by viewModel.prompt.collectAsStateWithLifecycle()

    fun launchChatGPTApp(prompt: String?) {
        if (!prompt.isNullOrBlank()) {
            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clip = ClipData.newPlainText("VinhCommand AI Prompt", prompt)
            clipboard.setPrimaryClip(clip)
            Toast.makeText(context, "Đã sao chép prompt và đang mở ChatGPT...", Toast.LENGTH_SHORT).show()
        }
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://chatgpt.com")).apply {
                setPackage("com.openai.chatgpt")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            val fallback = Intent(Intent.ACTION_VIEW, Uri.parse("https://chatgpt.com")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(fallback)
        }
    }

    fun launchGeminiApp(prompt: String?) {
        if (!prompt.isNullOrBlank()) {
            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clip = ClipData.newPlainText("VinhCommand AI Prompt", prompt)
            clipboard.setPrimaryClip(clip)
            Toast.makeText(context, "Đã sao chép prompt và đang mở Google Gemini...", Toast.LENGTH_SHORT).show()
        }
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://gemini.google.com")).apply {
                setPackage("com.google.android.apps.bard")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            val fallback = Intent(Intent.ACTION_VIEW, Uri.parse("https://gemini.google.com")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(fallback)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF161B22))
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    "DESKTOP AI AGENTS",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                    color = Color(0xFF4ADE80)
                )
                Text(
                    "Đồng bộ trực tiếp từ máy tính (Codex, Antigravity, OpenCode)",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFF9EA4B0)
                )
            }
            OutlinedButton(
                onClick = { onNavigateBack() },
                border = BorderStroke(1.dp, Color(0xFF3E4552)),
                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
            ) {
                Text("Đóng", color = Color(0xFFE2E4E9), style = MaterialTheme.typography.labelSmall)
            }
        }

        // Section: Mobile AI App Bridges (ChatGPT & Gemini)
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF1B1E23)),
            border = BorderStroke(1.dp, Color(0xFF4A7C59))
        ) {
            Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    "LIÊN KẾT ỨNG DỤNG AI TRÊN MOBILE",
                    style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                    color = Color(0xFF4ADE80)
                )
                Text(
                    "Mở trực tiếp ứng dụng ChatGPT hoặc Google Gemini đã cài trên điện thoại để tra cứu và lập trình:",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFF9EA4B0)
                )
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Button(
                        onClick = { launchChatGPTApp(promptText) },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF10A37F))
                    ) {
                        Text("Mở ChatGPT App", style = MaterialTheme.typography.labelMedium, color = Color.White)
                    }
                    Button(
                        onClick = { launchGeminiApp(promptText) },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1A73E8))
                    ) {
                        Text("Mở Gemini App", style = MaterialTheme.typography.labelMedium, color = Color.White)
                    }
                }
            }
        }

        // Section: Synced Desktop Agents List
        Text(
            "CÁC AI AGENT ĐÃ LIÊN KẾT TỪ DESKTOP:",
            style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
            color = Color(0xFF4ADE80)
        )

        // Default core fallback list if list is empty
        val displayAgents = remember(agents) {
            if (agents.isNotEmpty()) agents else listOf(
                AIAgent(
                    id = "antigravity",
                    name = "Google Antigravity",
                    description = "Google Antigravity CLI Agent (Codex.Antigravity)",
                    status = AgentStatus.AVAILABLE,
                    version = "1.0.0",
                    capabilities = com.vinhcommand.domain.model.AgentCapabilities(
                        prompt = true, streaming = true, terminal = false,
                        projectContext = true, stopControl = true, screenStream = false, remoteInput = false
                    ),
                    path = "C:\\Users\\ADMIN\\.gemini\\antigravity\\bin\\agentapi.bat"
                ),
                AIAgent(
                    id = "opencode",
                    name = "OpenCode AI",
                    description = "OpenCode Multi-Provider CLI (OpenAI Free, DeepSeek, GLM, ZenMux)",
                    status = AgentStatus.AVAILABLE,
                    version = "1.0.0",
                    capabilities = com.vinhcommand.domain.model.AgentCapabilities(
                        prompt = true, streaming = true, terminal = false,
                        projectContext = true, stopControl = true, screenStream = false, remoteInput = false
                    ),
                    path = "C:\\Users\\ADMIN\\AppData\\Roaming\\npm\\opencode.cmd"
                ),
                AIAgent(
                    id = "codex",
                    name = "OpenAI Codex",
                    description = "OpenAI Codex CLI Workspace Agent",
                    status = AgentStatus.AVAILABLE,
                    version = "1.0.0",
                    capabilities = com.vinhcommand.domain.model.AgentCapabilities(
                        prompt = true, streaming = true, terminal = false,
                        projectContext = true, stopControl = true, screenStream = false, remoteInput = false
                    ),
                    path = "C:\\Users\\ADMIN\\AppData\\Roaming\\npm\\codex.cmd"
                ),
                AIAgent(
                    id = "gemini",
                    name = "Google Gemini CLI",
                    description = "Google Gemini CLI & Online Web Bridge",
                    status = AgentStatus.AVAILABLE,
                    version = "1.0.0",
                    capabilities = com.vinhcommand.domain.model.AgentCapabilities(
                        prompt = true, streaming = true, terminal = false,
                        projectContext = true, stopControl = true, screenStream = false, remoteInput = false
                    ),
                    path = "C:\\Users\\ADMIN\\AppData\\Roaming\\npm\\gemini.cmd"
                ),
                AIAgent(
                    id = "claude",
                    name = "Claude Code",
                    description = "Anthropic Claude Code CLI Agent",
                    status = AgentStatus.AVAILABLE,
                    version = "1.0.0",
                    capabilities = com.vinhcommand.domain.model.AgentCapabilities(
                        prompt = true, streaming = true, terminal = false,
                        projectContext = true, stopControl = true, screenStream = false, remoteInput = false
                    ),
                    path = "C:\\Users\\ADMIN\\AppData\\Roaming\\npm\\claude.cmd"
                )
            )
        }

        displayAgents.forEach { agent ->
            val isSelected = selectedId == agent.id
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { viewModel.selectAgent(agent) },
                colors = CardDefaults.cardColors(
                    containerColor = if (isSelected) Color(0xFF2B3038) else Color(0xFF22262C)
                ),
                border = BorderStroke(1.dp, if (isSelected) Color(0xFF4A7C59) else Color(0xFF3E4552))
            ) {
                Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            agent.name,
                            style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold),
                            color = if (isSelected) Color(0xFF4ADE80) else Color(0xFFE2E4E9)
                        )
                        Surface(
                            color = when (agent.status) {
                                AgentStatus.AVAILABLE, AgentStatus.INSTALLED, AgentStatus.RUNNING -> Color(0xFF1B432C)
                                else -> Color(0xFF3E2723)
                            },
                            shape = MaterialTheme.shapes.extraSmall
                        ) {
                            Text(
                                " ${agent.status.name} ",
                                style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace),
                                color = when (agent.status) {
                                    AgentStatus.AVAILABLE, AgentStatus.INSTALLED, AgentStatus.RUNNING -> Color(0xFF4ADE80)
                                    else -> Color(0xFFFFB74D)
                                },
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }
                    Text(
                        agent.description.ifBlank { "Desktop AI Engine CLI" },
                        style = MaterialTheme.typography.bodySmall,
                        color = Color(0xFF9EA4B0)
                    )
                    agent.path?.let { p ->
                        Text(
                            "CLI Path: ${p.takeLast(45)}",
                            style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace),
                            color = Color(0xFF727885)
                        )
                    }
                }
            }
        }

        // Section: Prompt Box
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF1B1E23)),
            border = BorderStroke(1.dp, Color(0xFF3E4552))
        ) {
            Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    "THỬ NGHIỆM PROMPT CHO AGENT ĐANG CHỌN:",
                    style = MaterialTheme.typography.labelSmall,
                    color = Color(0xFF4ADE80)
                )
                OutlinedTextField(
                    value = promptText,
                    onValueChange = { viewModel.setPrompt(it) },
                    placeholder = { Text("Nhập câu hỏi hoặc lệnh sửa code...", style = MaterialTheme.typography.bodySmall) },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 2,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = Color(0xFF4A7C59),
                        unfocusedBorderColor = Color(0xFF3E4552),
                        focusedContainerColor = Color(0xFF161B22),
                        unfocusedContainerColor = Color(0xFF161B22)
                    )
                )
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Button(
                        onClick = { viewModel.sendPrompt("") },
                        enabled = promptText.isNotBlank() && selectedId != null,
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4A7C59))
                    ) {
                        Text("Gửi lệnh đến Desktop", color = Color.White)
                    }
                    OutlinedButton(
                        onClick = { launchChatGPTApp(promptText) },
                        modifier = Modifier.weight(1f),
                        border = BorderStroke(1.dp, Color(0xFF10A37F))
                    ) {
                        Text("Dán vào ChatGPT", color = Color(0xFF10A37F), style = MaterialTheme.typography.labelSmall)
                    }
                }
            }
        }
    }
}
