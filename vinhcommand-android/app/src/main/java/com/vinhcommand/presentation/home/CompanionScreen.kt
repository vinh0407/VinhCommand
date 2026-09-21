package com.vinhcommand.presentation.home

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vinhcommand.domain.model.*

@Composable
fun CompanionScreen(onReconnect: () -> Unit, viewModel: CompanionViewModel = hiltViewModel()) {
    val context = LocalContext.current
    val state by viewModel.state.collectAsStateWithLifecycle()
    val connection by viewModel.connectionState.collectAsStateWithLifecycle()
    val message by viewModel.message.collectAsStateWithLifecycle()
    val busy by viewModel.busy.collectAsStateWithLifecycle()

    var currentTab by remember { mutableStateOf("Home") }

    // Active project selection
    var selectedProjectId by remember { mutableStateOf<String?>(null) }
    val currentProject = state.projects.firstOrNull { it.id == selectedProjectId } ?: state.projects.firstOrNull()

    // Floating Workspace state
    val isProjectOverlayOpen by viewModel.isProjectOverlayOpen.collectAsStateWithLifecycle()
    val isProjectOverlayMinimized by viewModel.isProjectOverlayMinimized.collectAsStateWithLifecycle()
    val floatingProject by viewModel.floatingProject.collectAsStateWithLifecycle()

    // File Explorer & Editor states
    val fsCurrentPath by viewModel.fsCurrentPath.collectAsStateWithLifecycle()
    val fsParentPath by viewModel.fsParentPath.collectAsStateWithLifecycle()
    val fsFolders by viewModel.fsFolders.collectAsStateWithLifecycle()
    val fsFiles by viewModel.fsFiles.collectAsStateWithLifecycle()
    val fsLoading by viewModel.fsLoading.collectAsStateWithLifecycle()

    val activeFilePath by viewModel.activeFilePath.collectAsStateWithLifecycle()
    val activeFileName by viewModel.activeFileName.collectAsStateWithLifecycle()
    val activeFileContent by viewModel.activeFileContent.collectAsStateWithLifecycle()
    val isFileDirty by viewModel.isFileDirty.collectAsStateWithLifecycle()
    val fileLoading by viewModel.fileLoading.collectAsStateWithLifecycle()

    // Run Center states
    val detectedRunners by viewModel.detectedRunners.collectAsStateWithLifecycle()
    val activeRunners by viewModel.activeRunners.collectAsStateWithLifecycle()
    val runnerFramework by viewModel.runnerFramework.collectAsStateWithLifecycle()
    val runnerLoading by viewModel.runnerLoading.collectAsStateWithLifecycle()
    val runnerState by viewModel.runnerState.collectAsStateWithLifecycle()
    val isBuildingApk by viewModel.isBuildingApk.collectAsStateWithLifecycle()
    val apkDownloadUrl by viewModel.apkDownloadUrl.collectAsStateWithLifecycle()
    val activeRunnerPid by viewModel.activeRunnerPid.collectAsStateWithLifecycle()
    val activeWebUrl by viewModel.activeWebUrl.collectAsStateWithLifecycle()

    // AI Automation states
    val aiResponse by viewModel.aiResponse.collectAsStateWithLifecycle()
    val aiLoading by viewModel.aiLoading.collectAsStateWithLifecycle()
    val isAiOverlayOpen by viewModel.isAiOverlayOpen.collectAsStateWithLifecycle()
    val isAiOverlayMinimized by viewModel.isAiOverlayMinimized.collectAsStateWithLifecycle()
    var selectedAiProvider by remember { mutableStateOf("opencode") }
    var aiPromptText by remember { mutableStateOf("") }
    var followUpPrompt by remember { mutableStateOf("") }
    var showHeavyRunnerWarning by remember { mutableStateOf<com.vinhcommand.network.model.RunnerItem?>(null) }
    var aiMode by remember { mutableStateOf("assisted") }

    val opencodeProviders by viewModel.opencodeProviders.collectAsStateWithLifecycle()
    val opencodeModels by viewModel.opencodeModels.collectAsStateWithLifecycle()
    val selectedOpencodeProvider by viewModel.selectedOpencodeProvider.collectAsStateWithLifecycle()
    val selectedOpencodeModel by viewModel.selectedOpencodeModel.collectAsStateWithLifecycle()

    // Dialog states
    var showAddProjectDialog by remember { mutableStateOf(false) }
    var deleteProjectTarget by remember { mutableStateOf<Project?>(null) }
    var showCloneDialog by remember { mutableStateOf(false) }
    var cloneRepoUrl by remember { mutableStateOf("") }
    var cloneTargetDir by remember { mutableStateOf("") }
    var gitCommitMessage by remember { mutableStateOf("") }

    // GitHub auth states
    val githubUser by viewModel.githubUsername.collectAsStateWithLifecycle()
    val isGithubLoggedIn by viewModel.isGithubLoggedIn.collectAsStateWithLifecycle()
    var githubInputUser by remember { mutableStateOf("") }
    var githubInputToken by remember { mutableStateOf("") }

    // Terminal command
    var terminalInput by remember { mutableStateOf("") }

    // Automatically detect runners when project changes
    LaunchedEffect(currentProject?.id) {
        currentProject?.let { p ->
            viewModel.detectRunners(p.path)
            if (fsCurrentPath.isBlank()) {
                viewModel.browseFs(p.path)
            }
        }
    }

    fun openWebPreview(url: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            context.startActivity(intent)
        } catch (_: Exception) {}
    }

    fun launchChatGPTApp(prompt: String?) {
        if (!prompt.isNullOrBlank()) {
            try {
                val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                val clip = ClipData.newPlainText("VinhCommand AI Prompt", prompt)
                clipboard.setPrimaryClip(clip)
                Toast.makeText(context, "Đã sao chép prompt và đang mở ChatGPT...", Toast.LENGTH_SHORT).show()
            } catch (_: Exception) {}
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
            try {
                val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                val clip = ClipData.newPlainText("VinhCommand AI Prompt", prompt)
                clipboard.setPrimaryClip(clip)
                Toast.makeText(context, "Đã sao chép prompt và đang mở Google Gemini...", Toast.LENGTH_SHORT).show()
            } catch (_: Exception) {}
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

    // Dialog: Add Project from Desktop
    if (showAddProjectDialog) {
        AlertDialog(
            onDismissRequest = { showAddProjectDialog = false },
            title = { Text("Add Project from Desktop") },
            text = {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 480.dp)
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Text("Browse source directories on the connected desktop to add to your workspace list:", style = MaterialTheme.typography.bodySmall)

                    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant), modifier = Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text(if (fsCurrentPath.isBlank()) "Location: [Root / Drives]" else "Folder: $fsCurrentPath", style = MaterialTheme.typography.labelMedium)
                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                if (fsParentPath != null) {
                                    OutlinedButton(onClick = { viewModel.browseFs(fsParentPath) }, contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)) {
                                        Text("[Up Directory]", style = MaterialTheme.typography.labelSmall)
                                    }
                                }
                                OutlinedButton(onClick = { viewModel.browseFs(null) }, contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)) {
                                    Text("[Drives]", style = MaterialTheme.typography.labelSmall)
                                }
                            }
                        }
                    }

                    if (fsLoading) LinearProgressIndicator(modifier = Modifier.fillMaxWidth())

                    fsFolders.forEach { item ->
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(containerColor = if (item.isProject == true) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surface)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth().padding(8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f).padding(end = 8.dp)) {
                                    Text((if (item.isDrive == true) "[DRIVE] " else if (item.isProject == true) "[PROJECT] " else "[DIR] ") + item.name, style = MaterialTheme.typography.titleSmall)
                                    Text(item.framework ?: "", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                                }
                                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                    OutlinedButton(onClick = { viewModel.browseFs(item.path) }, contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)) {
                                        Text("Enter", style = MaterialTheme.typography.labelSmall)
                                    }
                                    Button(onClick = { viewModel.addProjectFromDesktop(item.path) { showAddProjectDialog = false } }, contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)) {
                                        Text("Add", style = MaterialTheme.typography.labelSmall)
                                    }
                                }
                            }
                        }
                    }
                    if (fsCurrentPath.isNotBlank()) {
                        HorizontalDivider()
                        Button(onClick = { viewModel.addProjectFromDesktop(fsCurrentPath) { showAddProjectDialog = false } }, modifier = Modifier.fillMaxWidth()) {
                            Text("Select Current Folder as Project")
                        }
                    }
                }
            },
            confirmButton = {},
            dismissButton = { TextButton(onClick = { showAddProjectDialog = false }) { Text("Close") } }
        )
    }

    // Dialog: Clone from GitHub
    if (showCloneDialog) {
        AlertDialog(
            onDismissRequest = { showCloneDialog = false },
            title = { Text("Download from GitHub (Clone Repo)") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Enter the remote repository URL and desktop destination directory:", style = MaterialTheme.typography.bodySmall)
                    OutlinedTextField(
                        value = cloneRepoUrl,
                        onValueChange = { cloneRepoUrl = it },
                        label = { Text("Repository URL") },
                        placeholder = { Text("https://github.com/user/repo.git") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                    OutlinedTextField(
                        value = cloneTargetDir,
                        onValueChange = { cloneTargetDir = it },
                        label = { Text("Desktop Target Directory") },
                        placeholder = { Text("C:\\VisualStudio\\repo") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (cloneRepoUrl.isNotBlank() && cloneTargetDir.isNotBlank()) {
                            viewModel.cloneGithubRepo(cloneRepoUrl, cloneTargetDir) {
                                showCloneDialog = false
                            }
                        }
                    },
                    enabled = cloneRepoUrl.isNotBlank() && cloneTargetDir.isNotBlank()
                ) {
                    Text("Clone")
                }
            },
            dismissButton = {
                TextButton(onClick = { showCloneDialog = false }) { Text("Cancel") }
            }
        )
    }

    // Dialog: Delete project confirmation
    if (deleteProjectTarget != null) {
        val p = deleteProjectTarget!!
        AlertDialog(
            onDismissRequest = { deleteProjectTarget = null },
            title = { Text("Remove Project") },
            text = { Text("Remove project '${p.name}' from your VinhCommand workspace?") },
            confirmButton = { TextButton(onClick = { deleteProjectTarget = null; viewModel.deleteProject(p.id) }) { Text("Remove") } },
            dismissButton = { TextButton(onClick = { deleteProjectTarget = null }) { Text("Cancel") } }
        )
    }

    // Dialog: Heavy runner notice for mobile
    if (showHeavyRunnerWarning != null) {
        val r = showHeavyRunnerWarning!!
        AlertDialog(
            onDismissRequest = { showHeavyRunnerWarning = null },
            title = { Text("Tác vụ nặng (Khuyên chạy trên Desktop)") },
            text = {
                Text("Lệnh '${r.command}' là tác vụ build nặng (Gradle/Cargo/Native). Bản mobile tối ưu cho các dự án cơ bản và máy nhẹ (Python, Node, Web dev). Bạn vẫn muốn gửi lệnh chạy sang máy tính Desktop?")
            },
            confirmButton = {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedButton(
                        onClick = {
                            val runnerToRun = r
                            showHeavyRunnerWarning = null
                            currentProject?.let { p ->
                                viewModel.startRunner(runnerToRun.command, p.path, runnerToRun.port ?: 5173, openCmd = true) { previewUrl ->
                                    if (previewUrl != null) openWebPreview(previewUrl)
                                }
                            }
                        }
                    ) {
                        Text("Mở CMD")
                    }
                    Button(
                        onClick = {
                            val runnerToRun = r
                            showHeavyRunnerWarning = null
                            currentProject?.let { p ->
                                viewModel.startRunner(runnerToRun.command, p.path, runnerToRun.port ?: 5173, openCmd = false) { previewUrl ->
                                    if (previewUrl != null) openWebPreview(previewUrl)
                                }
                            }
                        }
                    ) {
                        Text("Chạy nền PC")
                    }
                }
            },
            dismissButton = {
                TextButton(onClick = { showHeavyRunnerWarning = null }) {
                    Text("Hủy")
                }
            }
        )
    }

    Scaffold(
        topBar = {
            Surface(color = MaterialTheme.colorScheme.surfaceColorAtElevation(3.dp), modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.safeDrawingPadding().padding(horizontal = 16.dp, vertical = 8.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("VINHCOMMAND IDE", style = MaterialTheme.typography.titleMedium.copy(fontFamily = FontFamily.Monospace), color = MaterialTheme.colorScheme.primary)
                            Text(currentProject?.name ?: "No project selected", style = MaterialTheme.typography.labelMedium)
                        }
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Surface(
                                color = if (connection == ConnectionState.CONNECTED) Color(0xFF2E7D32) else MaterialTheme.colorScheme.error,
                                shape = MaterialTheme.shapes.extraSmall
                            ) {
                                Text(
                                    if (connection == ConnectionState.CONNECTED) " PC ONLINE " else " OFFLINE ",
                                    color = Color.White,
                                    style = MaterialTheme.typography.labelSmall,
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                )
                            }
                            OutlinedButton(onClick = { viewModel.disconnect(); onReconnect() }, contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp)) {
                                Text("Switch PC", style = MaterialTheme.typography.labelSmall)
                            }
                        }
                    }
                    message?.let {
                        Text(it, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.secondary, modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite })
                    }
                }
            }
        },
        bottomBar = {
            NavigationBar(
                containerColor = Color(0xFF1B1E23),
                contentColor = Color(0xFFE2E4E9),
                modifier = Modifier.height(64.dp)
            ) {
                listOf(
                    Pair("Home", "Home"),
                    Pair("Project", "Project"),
                    Pair("AI", "AI"),
                    Pair("Run", "Run"),
                    Pair("Terminal", "Terminal"),
                    Pair("More", "More")
                ).forEach { (id, label) ->
                    NavigationBarItem(
                        selected = currentTab == id,
                        onClick = { currentTab = id },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = Color(0xFF4ADE80),
                            selectedTextColor = Color(0xFF4ADE80),
                            indicatorColor = Color(0xFF2B3038),
                            unselectedIconColor = Color(0xFF727885),
                            unselectedTextColor = Color(0xFF727885)
                        ),
                        icon = {
                            Text(
                                when (id) {
                                    "Home" -> "[HOME]"
                                    "Project" -> "[CODE]"
                                    "AI" -> "[AI]"
                                    "Run" -> "[RUN]"
                                    "Terminal" -> "[TERM]"
                                    else -> "[MORE]"
                                },
                                style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace)
                            )
                        },
                        label = { Text(label, style = MaterialTheme.typography.labelSmall) }
                    )
                }
            }
        }
    ) { innerPadding ->
        Box(modifier = Modifier.fillMaxSize().padding(innerPadding)) {
            when (currentTab) {
                // ==================== TAB 1: HOME ====================
                "Home" -> {
                    Column(
                        modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant), modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Text("CONNECTED DESKTOP", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                                Text(state.computer?.name ?: "VinhCommand Core Engine", style = MaterialTheme.typography.titleLarge)
                                Text("Address: ${state.computer?.ipAddress ?: "127.0.0.1"}:8444 · Connection: ${connection.name}")
                            }
                        }

                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                    Text("ACTIVE PROJECT", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                                    OutlinedButton(onClick = { currentTab = "Project" }, contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)) {
                                        Text("Projects List", style = MaterialTheme.typography.labelSmall)
                                    }
                                }
                                Text(currentProject?.name ?: "No project selected", style = MaterialTheme.typography.titleMedium)
                                SelectionContainer { Text(currentProject?.path ?: "", style = MaterialTheme.typography.bodySmall) }
                                Text("Branch: ${currentProject?.gitBranch?.ifBlank { "main" } ?: "main"} · Language: ${currentProject?.language?.ifBlank { "Auto-detected" } ?: "Auto-detected"}")
                            }
                        }

                        Text("QUICK WORKFLOW ACTIONS", style = MaterialTheme.typography.titleSmall)
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Button(onClick = { currentProject?.let { viewModel.openProjectOverlay(it) } }, modifier = Modifier.weight(1f)) {
                                Text("Open IDE Window")
                            }
                            Button(onClick = { currentTab = "Run"; currentProject?.let { viewModel.detectRunners(it.path) } }, modifier = Modifier.weight(1f)) {
                                Text("Run Project")
                            }
                        }
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            OutlinedButton(onClick = { currentTab = "AI" }, modifier = Modifier.weight(1f)) {
                                Text("AI Coding Center")
                            }
                            OutlinedButton(onClick = { currentTab = "Terminal" }, modifier = Modifier.weight(1f)) {
                                Text("Terminal Console")
                            }
                        }

                        if (state.tasks.isNotEmpty()) {
                            Text("MASTER PROJECT TASKS (1 PER PROJECT)", style = MaterialTheme.typography.titleSmall, color = Color(0xFF4ADE80))
                            val masterTasksByProject = remember(state.tasks, state.projects) {
                                state.tasks
                                    .groupBy { it.projectId }
                                    .mapNotNull { (pId, tasks) ->
                                        val pName = state.projects.firstOrNull { it.id == pId }?.name ?: "Project ($pId)"
                                        val latest = tasks.maxByOrNull { it.createdAt } ?: tasks.first()
                                        Triple(pName, latest, tasks.size)
                                    }
                            }
                            masterTasksByProject.forEach { (pName, t, totalCount) ->
                                Card(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clickable {
                                            selectedProjectId = t.projectId
                                            viewModel.openAiOverlay()
                                        },
                                    colors = CardDefaults.cardColors(containerColor = Color(0xFF22262C)),
                                    border = BorderStroke(1.dp, Color(0xFF3E4552))
                                ) {
                                    Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                            Text(pName, style = MaterialTheme.typography.titleSmall, color = Color(0xFF4ADE80))
                                            Surface(
                                                color = when (t.status.name) {
                                                    "SUCCESS" -> Color(0xFF1B432C)
                                                    "RUNNING" -> Color(0xFF1B3B4B)
                                                    "FAILED" -> Color(0xFF4B1B1B)
                                                    else -> Color(0xFF2B3038)
                                                },
                                                shape = MaterialTheme.shapes.extraSmall
                                            ) {
                                                Text(
                                                    " ${t.status.name} ($totalCount tasks) ",
                                                    style = MaterialTheme.typography.labelSmall,
                                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                                    color = when (t.status.name) {
                                                        "SUCCESS" -> Color(0xFF4ADE80)
                                                        "RUNNING" -> Color(0xFF64B5F6)
                                                        "FAILED" -> Color(0xFFE57373)
                                                        else -> Color(0xFF9EA4B0)
                                                    }
                                                )
                                            }
                                        }
                                        Text(t.prompt, style = MaterialTheme.typography.bodySmall, color = Color(0xFFE2E4E9), maxLines = 2)
                                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                            Text("AI: ${t.agentName}", style = MaterialTheme.typography.labelSmall, color = Color(0xFF9EA4B0))
                                            OutlinedButton(
                                                onClick = {
                                                    selectedProjectId = t.projectId
                                                    viewModel.openAiOverlay()
                                                },
                                                contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp),
                                                border = BorderStroke(1.dp, Color(0xFF4A7C59))
                                            ) {
                                                Text("Open AI Window", color = Color(0xFF4ADE80), style = MaterialTheme.typography.labelSmall)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ==================== TAB 2: PROJECT (ADD PROJECTS FOR AI CODING & FLOATING IDE) ====================
                "Project" -> {
                    Column(
                        modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text("PROJECTS WORKSPACE", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
                                Text("Add and manage projects for AI coding", style = MaterialTheme.typography.bodySmall)
                            }
                            Button(onClick = { viewModel.browseFs(null); showAddProjectDialog = true }) {
                                Text("Add Project")
                            }
                        }

                        if (state.projects.isEmpty()) {
                            Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant), modifier = Modifier.fillMaxWidth()) {
                                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Text("No projects added yet.", style = MaterialTheme.typography.titleSmall)
                                    Text("Add desktop directories to this list so AI agents can inspect, analyze, and directly modify your code.")
                                    Button(onClick = { viewModel.browseFs(null); showAddProjectDialog = true }) {
                                        Text("Browse Desktop Folders")
                                    }
                                }
                            }
                        }

                        state.projects.forEach { prj ->
                            Card(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        selectedProjectId = prj.id
                                        viewModel.openProjectOverlay(prj)
                                    },
                                colors = CardDefaults.cardColors(
                                    containerColor = if (prj.id == currentProject?.id) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surface
                                )
                            ) {
                                Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                        Text(prj.name, style = MaterialTheme.typography.titleMedium.copy(fontFamily = FontFamily.Monospace))
                                        Text(prj.framework.ifBlank { "Project" }, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                                    }
                                    SelectionContainer { Text(prj.path, style = MaterialTheme.typography.bodySmall) }
                                    Text("Branch: ${prj.gitBranch.ifBlank { "main" }} · Modified Files: ${prj.modifiedFilesCount}", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline)

                                     Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                         Button(
                                             onClick = {
                                                 selectedProjectId = prj.id
                                                 viewModel.openProjectOverlay(prj)
                                             },
                                             contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                                         ) {
                                             Text("Open IDE")
                                         }
                                         Button(
                                             onClick = {
                                                 selectedProjectId = prj.id
                                                 viewModel.openAiOverlay()
                                             },
                                             colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2E7D32)),
                                             contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                                         ) {
                                             Text("Task Tổng", color = Color.White)
                                         }
                                         OutlinedButton(
                                             onClick = {
                                                 selectedProjectId = prj.id
                                                 currentTab = "AI"
                                             },
                                             contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                                         ) {
                                             Text("AI Code")
                                         }
                                         OutlinedButton(
                                             onClick = { deleteProjectTarget = prj },
                                             contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                                         ) {
                                             Text("Remove")
                                         }
                                     }
                                }
                            }
                        }
                    }
                }

                // ==================== TAB 3: AI (AI CODING CENTER) ====================
                "AI" -> {
                    Column(
                        modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        Text("AI CODING CENTER", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
                        Text("Direct prompt execution to Desktop AI Engines without manual copy/paste. Codex and Antigravity run on PC to directly modify workspace files.", style = MaterialTheme.typography.bodySmall)

                        // 1. Target Project Selector
                        Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant), modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                Text("TARGET PROJECT:", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                                if (state.projects.isEmpty()) {
                                    Text("No projects available. Add one in the Project tab first.", style = MaterialTheme.typography.bodySmall)
                                } else {
                                    Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                        state.projects.forEach { prj ->
                                            FilterChip(
                                                selected = (currentProject?.id == prj.id),
                                                onClick = { selectedProjectId = prj.id },
                                                label = { Text(prj.name) }
                                            )
                                        }
                                    }
                                }
                            }
                        }

                        // Project's Master Task (Task Tổng Hợp & Lịch Sử Chat)
                        val projectMasterTask = remember(state.tasks, currentProject?.id) {
                            state.tasks.firstOrNull { it.id == "master_${currentProject?.id}" }
                                ?: state.tasks.firstOrNull { it.projectId == currentProject?.id }
                        }

                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFF1B232E)),
                            border = BorderStroke(1.dp, Color(0xFF4A7C59))
                        ) {
                            Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                        Surface(color = Color(0xFF2E7D32), shape = MaterialTheme.shapes.extraSmall) {
                                            Text(
                                                " TASK TỔNG DỰ ÁN ",
                                                color = Color.White,
                                                style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                            )
                                        }
                                        Text(
                                            currentProject?.name ?: "Chưa chọn dự án",
                                            style = MaterialTheme.typography.titleSmall.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                                            color = Color(0xFF4ADE80)
                                        )
                                    }
                                    if (projectMasterTask != null) {
                                        Surface(
                                            color = Color(0xFF1B432C),
                                            shape = MaterialTheme.shapes.extraSmall
                                        ) {
                                            Text(
                                                "${projectMasterTask.logs.size} tin nhắn",
                                                color = Color(0xFF4ADE80),
                                                style = MaterialTheme.typography.labelSmall,
                                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                            )
                                        }
                                    }
                                }

                                if (projectMasterTask != null) {
                                    Text(
                                        "Agent: ${projectMasterTask.agentName} · Trạng thái: ${projectMasterTask.status.name}",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color(0xFF9EA4B0)
                                    )
                                    Text(
                                        "Gần nhất: ${projectMasterTask.prompt}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color(0xFFE2E4E9),
                                        maxLines = 2
                                    )
                                    Button(
                                        onClick = { viewModel.openAiOverlay() },
                                        modifier = Modifier.fillMaxWidth(),
                                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2E7D32))
                                    ) {
                                        Text(
                                            "MỞ LỊCH SỬ CHAT & SỬA CODE TRỰC TIẾP",
                                            color = Color.White,
                                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold)
                                        )
                                    }
                                } else {
                                    Text(
                                        "Mỗi dự án có 1 Task Tổng lưu toàn bộ lịch sử hỏi AI và code sửa đổi. Nhập prompt bên dưới để AI khởi tạo Task Tổng và sửa file trên PC!",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color(0xFF9EA4B0)
                                    )
                                    OutlinedButton(
                                        onClick = { viewModel.openAiOverlay() },
                                        modifier = Modifier.fillMaxWidth(),
                                        border = BorderStroke(1.dp, Color(0xFF4A7C59))
                                    ) {
                                        Text("Mở Cửa Sổ Task Tổng & Editor", color = Color(0xFF4ADE80), style = MaterialTheme.typography.labelSmall)
                                    }
                                }
                            }
                        }

                        // 2. AI Engine Selector with Scan Button
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("SELECT AI AGENT ENGINE:", style = MaterialTheme.typography.labelMedium, color = Color(0xFF4ADE80))
                            OutlinedButton(
                                onClick = { viewModel.scanAiAgents() },
                                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 2.dp),
                                border = BorderStroke(1.dp, Color(0xFF4A7C59)),
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFF4ADE80))
                            ) {
                                Text("SCAN AI AGENTS", style = MaterialTheme.typography.labelSmall)
                            }
                        }

                        // Section: Mobile Native AI Apps (ChatGPT & Gemini)
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFF1B1E23)),
                            border = BorderStroke(1.dp, Color(0xFF4A7C59))
                        ) {
                            Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                    Text("LIÊN KẾT ỨNG DỤNG AI TRÊN MOBILE", style = MaterialTheme.typography.labelMedium.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold), color = Color(0xFF4ADE80))
                                    Text("NATIVE APPS", style = MaterialTheme.typography.labelSmall, color = Color(0xFF9EA4B0))
                                }
                                Text("Mở trực tiếp ứng dụng ChatGPT hoặc Gemini trên điện thoại (tự động sao chép prompt):", style = MaterialTheme.typography.bodySmall, color = Color(0xFF9EA4B0))
                                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Button(
                                        onClick = { launchChatGPTApp(aiPromptText) },
                                        modifier = Modifier.weight(1f),
                                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF10A37F))
                                    ) {
                                        Text("Mở ChatGPT App", style = MaterialTheme.typography.labelSmall, color = Color.White)
                                    }
                                    Button(
                                        onClick = { launchGeminiApp(aiPromptText) },
                                        modifier = Modifier.weight(1f),
                                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1A73E8))
                                    ) {
                                        Text("Mở Gemini App", style = MaterialTheme.typography.labelSmall, color = Color.White)
                                    }
                                }
                            }
                        }

                        val allAiEngines = remember(state.agents) {
                            val coreEngines = listOf(
                                Triple("antigravity_desktop", "Google Antigravity CLI", "Direct PC CLI Engine (Codex.Antigravity) • Tự động sửa code trên PC"),
                                Triple("opencode", "OpenCode AI (Free Models)", "Free CLI Engine • OpenAI GPT-4o-mini, DeepSeek, GLM-4 Free"),
                                Triple("codex_desktop", "OpenAI Codex CLI", "Direct PC CLI Engine • npm/codex.cmd"),
                                Triple("gemini_desktop", "Google Gemini CLI", "Direct PC CLI Engine • npm/gemini.cmd"),
                                Triple("claude_desktop", "Claude Code CLI", "Direct PC CLI Engine • npm/claude.cmd")
                            )
                            if (state.agents.isEmpty()) {
                                coreEngines
                            } else {
                                val mapped = state.agents.map { agent ->
                                    val providerKey = when {
                                        agent.name.contains("antigravity", ignoreCase = true) -> "antigravity_desktop"
                                        agent.name.contains("codex", ignoreCase = true) -> "codex_desktop"
                                        agent.name.contains("gemini", ignoreCase = true) -> "gemini_desktop"
                                        agent.name.contains("claude", ignoreCase = true) -> "claude_desktop"
                                        agent.name.contains("opencode", ignoreCase = true) -> "opencode"
                                        else -> agent.name.lowercase().replace(" ", "_")
                                    }
                                    Triple(
                                        providerKey,
                                        "${agent.name} (Desktop CLI)",
                                        "PC CLI Agent (${agent.status.name}) • ${agent.path?.takeLast(35) ?: "Local Desktop Agent"}"
                                    )
                                }
                                (mapped + coreEngines).distinctBy { it.first }
                            }
                        }

                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            allAiEngines.forEach { (agentId, name, desc) ->
                                Card(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clickable { selectedAiProvider = agentId },
                                    colors = CardDefaults.cardColors(
                                        containerColor = if (selectedAiProvider == agentId) Color(0xFF2B3038) else Color(0xFF22262C)
                                    ),
                                    border = BorderStroke(1.dp, if (selectedAiProvider == agentId) Color(0xFF4A7C59) else Color(0xFF3E4552))
                                ) {
                                    Row(Modifier.fillMaxWidth().padding(10.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                                        Column(Modifier.weight(1f)) {
                                            Text(name, style = MaterialTheme.typography.titleSmall, color = if (selectedAiProvider == agentId) Color(0xFF4ADE80) else Color(0xFFE2E4E9))
                                            Text(desc, style = MaterialTheme.typography.labelSmall, color = Color(0xFF9EA4B0))
                                        }
                                        RadioButton(
                                            selected = (selectedAiProvider == agentId),
                                            onClick = { selectedAiProvider = agentId },
                                            colors = RadioButtonDefaults.colors(
                                                selectedColor = Color(0xFF4ADE80),
                                                unselectedColor = Color(0xFF727885)
                                            )
                                        )
                                    }
                                }
                            }
                        }

                        if (selectedAiProvider.contains("opencode")) {
                            Card(
                                modifier = Modifier.fillMaxWidth(),
                                colors = CardDefaults.cardColors(containerColor = Color(0xFF1E2228)),
                                border = BorderStroke(1.dp, Color(0xFF4A7C59))
                            ) {
                                Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text("OPENCODE PROVIDER", style = MaterialTheme.typography.labelMedium, color = Color(0xFF4ADE80))
                                        Text("FREE MODELS AVAILABLE", style = MaterialTheme.typography.labelSmall, color = Color(0xFF4ADE80))
                                    }
                                    Row(
                                        Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        opencodeProviders.forEach { prov ->
                                            FilterChip(
                                                selected = (selectedOpencodeProvider == prov.id),
                                                onClick = { viewModel.selectOpencodeProvider(prov.id) },
                                                label = {
                                                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                                        Text(prov.name, style = MaterialTheme.typography.labelSmall)
                                                        if (prov.hasFreeModels) {
                                                            Text("[FREE]", color = Color(0xFF4ADE80), style = MaterialTheme.typography.labelSmall)
                                                        }
                                                    }
                                                },
                                                colors = FilterChipDefaults.filterChipColors(
                                                    selectedContainerColor = Color(0xFF386345),
                                                    selectedLabelColor = Color.White,
                                                    containerColor = Color(0xFF2B3038),
                                                    labelColor = Color(0xFFE2E4E9)
                                                ),
                                                border = BorderStroke(1.dp, if (selectedOpencodeProvider == prov.id) Color(0xFF4A7C59) else Color(0xFF3E4552))
                                            )
                                        }
                                    }

                                    Text("SELECT MODEL (FREE PRIORITIZED):", style = MaterialTheme.typography.labelMedium, color = Color(0xFF4ADE80))
                                    val filteredModels = remember(opencodeModels, selectedOpencodeProvider) {
                                        opencodeModels.filter { it.providerId == selectedOpencodeProvider }
                                            .sortedWith(compareByDescending<com.vinhcommand.network.model.OpencodeModelDto> { it.isFree }.thenBy { it.displayName })
                                    }

                                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                        filteredModels.forEach { modelItem ->
                                            val isChosen = selectedOpencodeModel == modelItem.id
                                            Card(
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .clickable { viewModel.selectOpencodeModel(modelItem.id) },
                                                colors = CardDefaults.cardColors(
                                                    containerColor = if (isChosen) Color(0xFF2B3038) else Color(0xFF22262C)
                                                ),
                                                border = BorderStroke(1.dp, if (isChosen) Color(0xFF4A7C59) else if (modelItem.isFree) Color(0xFF386345) else Color(0xFF3E4552))
                                            ) {
                                                Row(
                                                    Modifier.fillMaxWidth().padding(8.dp),
                                                    verticalAlignment = Alignment.CenterVertically,
                                                    horizontalArrangement = Arrangement.SpaceBetween
                                                ) {
                                                    Column(Modifier.weight(1f)) {
                                                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                                            if (modelItem.isFree) {
                                                                Surface(
                                                                    color = Color(0xFF1B432C),
                                                                    shape = androidx.compose.foundation.shape.RoundedCornerShape(4.dp)
                                                                ) {
                                                                    Text(
                                                                        "FREE",
                                                                        color = Color(0xFF4ADE80),
                                                                        style = MaterialTheme.typography.labelSmall,
                                                                        modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                                                                    )
                                                                }
                                                            }
                                                            Text(
                                                                modelItem.displayName,
                                                                style = MaterialTheme.typography.titleSmall,
                                                                color = if (isChosen || modelItem.isFree) Color(0xFF4ADE80) else Color(0xFFE2E4E9)
                                                            )
                                                        }
                                                        if (modelItem.description.isNotBlank()) {
                                                            Text(
                                                                modelItem.description,
                                                                style = MaterialTheme.typography.labelSmall,
                                                                color = Color(0xFF9EA4B0)
                                                            )
                                                        }
                                                    }
                                                    RadioButton(
                                                        selected = isChosen,
                                                        onClick = { viewModel.selectOpencodeModel(modelItem.id) },
                                                        colors = RadioButtonDefaults.colors(
                                                            selectedColor = Color(0xFF4ADE80),
                                                            unselectedColor = Color(0xFF727885)
                                                        )
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 3. Execution Mode
                        Text("EXECUTION MODE:", style = MaterialTheme.typography.labelMedium)
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            listOf(
                                Pair("ask", "Ask Only"),
                                Pair("assisted", "Assisted (Diff Patch)"),
                                Pair("autonomous", "Autonomous (Auto Edit)")
                            ).forEach { (m, label) ->
                                FilterChip(
                                    selected = aiMode == m,
                                    onClick = { aiMode = m },
                                    label = { Text(label, style = MaterialTheme.typography.labelSmall) },
                                    colors = FilterChipDefaults.filterChipColors(
                                        selectedContainerColor = Color(0xFF386345),
                                        selectedLabelColor = Color.White,
                                        containerColor = Color(0xFF22262C),
                                        labelColor = Color(0xFFE2E4E9)
                                    ),
                                    border = BorderStroke(1.dp, if (aiMode == m) Color(0xFF4A7C59) else Color(0xFF3E4552))
                                )
                            }
                        }

                        // 4. Prompt Input
                        OutlinedTextField(
                            value = aiPromptText,
                            onValueChange = { aiPromptText = it },
                            label = { Text("AI Coding Prompt") },
                            placeholder = { Text("E.g.: Fix authentication error, handle null exceptions, and add unit tests...") },
                            modifier = Modifier.fillMaxWidth(),
                            minLines = 3,
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = Color(0xFF4A7C59),
                                unfocusedBorderColor = Color(0xFF3E4552),
                                focusedContainerColor = Color(0xFF1B1E23),
                                unfocusedContainerColor = Color(0xFF1B1E23)
                            )
                        )

                        Button(
                            onClick = {
                                currentProject?.let { p ->
                                    viewModel.runAiAutomate(
                                        provider = selectedAiProvider,
                                        prompt = aiPromptText,
                                        projectPath = p.path,
                                        currentFile = activeFilePath,
                                        selectedCode = null,
                                        mode = aiMode,
                                        model = if (selectedAiProvider.contains("opencode")) selectedOpencodeModel else null
                                    )
                                }
                            },
                            enabled = !aiLoading && aiPromptText.isNotBlank() && currentProject != null,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Color(0xFF4A7C59),
                                disabledContainerColor = Color(0xFF2B3038)
                            ),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(if (aiLoading) "AI Processing & Modifying..." else "RUN AI & MODIFY CODE", color = Color.White)
                        }

                        if (aiLoading) LinearProgressIndicator(modifier = Modifier.fillMaxWidth(), color = Color(0xFF4A7C59))

                        // 5. Diff & Response Display
                        aiResponse?.let { resp ->
                            Card(
                                modifier = Modifier.fillMaxWidth(),
                                colors = CardDefaults.cardColors(containerColor = Color(0xFF22262C)),
                                border = BorderStroke(1.dp, Color(0xFF4A7C59))
                            ) {
                                Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                        Text("RESULT FROM ${resp.provider.uppercase()}", style = MaterialTheme.typography.titleSmall, color = Color(0xFF4ADE80))
                                        OutlinedButton(
                                            onClick = { viewModel.openAiOverlay() },
                                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp),
                                            border = BorderStroke(1.dp, Color(0xFF4A7C59))
                                        ) {
                                            Text("Open Floating Window", color = Color(0xFF4ADE80), style = MaterialTheme.typography.labelSmall)
                                        }
                                    }
                                    SelectionContainer {
                                        Text(resp.reply, style = MaterialTheme.typography.bodyMedium, color = Color(0xFFE2E4E9))
                                    }

                                    if (resp.changedFiles.isNotEmpty()) {
                                        Text("Modified Files (${resp.changedFiles.size}): ${resp.changedFiles.joinToString(", ")}", style = MaterialTheme.typography.labelMedium, color = Color(0xFF9EA4B0))
                                    }

                                    if (resp.diff.isNotBlank()) {
                                        Text("Diff Patch:", style = MaterialTheme.typography.labelSmall, color = Color(0xFF9EA4B0))
                                        Surface(
                                            color = Color(0xFF1B1E23),
                                            shape = MaterialTheme.shapes.extraSmall,
                                            border = BorderStroke(1.dp, Color(0xFF3E4552)),
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            SelectionContainer {
                                                Text(
                                                    resp.diff,
                                                    modifier = Modifier.padding(8.dp),
                                                    style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace, color = Color(0xFF4ADE80))
                                                )
                                            }
                                        }
                                    }

                                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                        Button(
                                            onClick = { viewModel.applyAiPatch() },
                                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2E7D32)),
                                            modifier = Modifier.weight(1f)
                                        ) {
                                            Text("Apply Changes", color = Color.White)
                                        }
                                        OutlinedButton(
                                            onClick = { viewModel.rejectAiPatch() },
                                            border = BorderStroke(1.dp, Color(0xFF3E4552)),
                                            modifier = Modifier.weight(1f)
                                        ) {
                                            Text("Reject", color = Color(0xFFE2E4E9))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ==================== TAB 4: RUN (RUN CENTER & WEB PREVIEW) ====================
                "Run" -> {
                    Column(
                        modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        Text("RUN CENTER & WEB PREVIEW", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
                        Text("Select a project, start dev servers or build commands, and preview web apps directly on this mobile device.", style = MaterialTheme.typography.bodySmall)

                        // 1. Project Selector
                        Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant), modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                    Text("SELECT PROJECT TO RUN:", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                                    OutlinedButton(onClick = { currentProject?.let { viewModel.detectRunners(it.path) } }, contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)) {
                                        Text("Scan Scripts", style = MaterialTheme.typography.labelSmall)
                                    }
                                }
                                if (state.projects.isEmpty()) {
                                    Text("No projects available. Add a project first.", style = MaterialTheme.typography.bodySmall)
                                } else {
                                    Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                        state.projects.forEach { prj ->
                                            FilterChip(
                                                selected = (currentProject?.id == prj.id),
                                                onClick = {
                                                    selectedProjectId = prj.id
                                                    viewModel.detectRunners(prj.path)
                                                },
                                                label = { Text(prj.name) }
                                            )
                                        }
                                    }
                                }
                                Text("Environment: $runnerFramework · ${currentProject?.path ?: ""}", style = MaterialTheme.typography.labelSmall)
                            }
                        }

                        if (runnerLoading) LinearProgressIndicator(modifier = Modifier.fillMaxWidth())

                        // 2. Detected Scripts (Lightweight Mobile vs Heavy Desktop)
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                            Text("DETECTED COMMANDS:", style = MaterialTheme.typography.labelMedium)
                            Surface(color = Color(0xFF1B432C), shape = MaterialTheme.shapes.extraSmall) {
                                Text(" MOBILE: CƠ BẢN / MÁY NHẸ ", color = Color(0xFF4ADE80), style = MaterialTheme.typography.labelSmall, modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
                            }
                        }
                        if (detectedRunners.isEmpty()) {
                            Text("No runnable scripts found for this project.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.outline)
                        }
                        detectedRunners.forEach { runner ->
                            val cmdLower = runner.command.lowercase()
                            val isLightweight = cmdLower.contains("python") ||
                                                cmdLower.contains("node") ||
                                                cmdLower.contains("npm start") ||
                                                cmdLower.contains("npm run dev") ||
                                                cmdLower.contains("vite") ||
                                                cmdLower.contains("serve") ||
                                                cmdLower.contains("flask") ||
                                                cmdLower.contains("uvicorn") ||
                                                runner.type == "dev" ||
                                                (!cmdLower.contains("assembledebug") &&
                                                 !cmdLower.contains("cargo") &&
                                                 !cmdLower.contains("cmake") &&
                                                 !cmdLower.contains("gradlew"))

                            Card(
                                modifier = Modifier.fillMaxWidth(),
                                colors = CardDefaults.cardColors(containerColor = if (isLightweight) Color(0xFF22262C) else Color(0xFF1E1E22)),
                                border = BorderStroke(1.dp, if (isLightweight) Color(0xFF4A7C59) else Color(0xFF3E4552))
                            ) {
                                Row(Modifier.fillMaxWidth().padding(12.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                    Column(Modifier.weight(1f).padding(end = 8.dp)) {
                                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                            Surface(
                                                color = if (isLightweight) Color(0xFF1B432C) else Color(0xFF3B2E1E),
                                                shape = MaterialTheme.shapes.extraSmall
                                            ) {
                                                Text(
                                                    if (isLightweight) " CƠ BẢN / MÁY NHẸ " else " NẶNG (PC) ",
                                                    color = if (isLightweight) Color(0xFF4ADE80) else Color(0xFFFFB74D),
                                                    style = MaterialTheme.typography.labelSmall,
                                                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp)
                                                )
                                            }
                                            Text(runner.name, style = MaterialTheme.typography.bodyMedium.copy(fontFamily = FontFamily.Monospace), color = Color(0xFFE2E4E9))
                                        }
                                        Text("${runner.command} ${if (runner.port != null) "· Port: ${runner.port}" else ""}", style = MaterialTheme.typography.labelSmall, color = Color(0xFF9EA4B0))
                                    }
                                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                                        OutlinedButton(
                                            onClick = {
                                                currentProject?.let { p ->
                                                    viewModel.startRunner(runner.command, p.path, runner.port ?: 5173, openCmd = true) { previewUrl ->
                                                        if (previewUrl != null) openWebPreview(previewUrl)
                                                    }
                                                }
                                            },
                                            border = BorderStroke(1.dp, Color(0xFF4ADE80)),
                                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                                        ) {
                                            Text("Mở CMD", color = Color(0xFF4ADE80), style = MaterialTheme.typography.labelSmall)
                                        }
                                        Button(
                                            onClick = {
                                                if (!isLightweight) {
                                                    showHeavyRunnerWarning = runner
                                                } else {
                                                    currentProject?.let { p ->
                                                        viewModel.startRunner(runner.command, p.path, runner.port ?: 5173, openCmd = false) { previewUrl ->
                                                            if (previewUrl != null) openWebPreview(previewUrl)
                                                        }
                                                    }
                                                }
                                            },
                                            colors = ButtonDefaults.buttonColors(containerColor = if (isLightweight) Color(0xFF4A7C59) else Color(0xFF6B5838)),
                                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                                        ) {
                                            Text("Chạy nền", style = MaterialTheme.typography.labelSmall)
                                        }
                                    }
                                }
                            }
                        }

                        // 3. Active Runners
                        HorizontalDivider()
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                            Text("RUNNING PROCESSES (${activeRunners.size}):", style = MaterialTheme.typography.labelMedium)
                            OutlinedButton(onClick = { viewModel.refreshRunners() }, contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)) {
                                Text("Refresh", style = MaterialTheme.typography.labelSmall)
                            }
                        }

                        if (activeRunners.isEmpty()) {
                            Text("No servers currently running.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.outline)
                        }

                        activeRunners.forEach { proc ->
                            Card(
                                modifier = Modifier.fillMaxWidth(),
                                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
                            ) {
                                Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                        Text("PID #${proc.pid} · ${proc.status}", style = MaterialTheme.typography.titleSmall, color = Color(0xFF2E7D32))
                                        Button(
                                            onClick = { viewModel.stopRunner(proc.pid) },
                                            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
                                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                                        ) {
                                            Text("Stop", style = MaterialTheme.typography.labelSmall)
                                        }
                                    }
                                    Text("Command: ${proc.command}", style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace))
                                    if (proc.previewUrl != null) {
                                        Text("LAN URL: ${proc.previewUrl}", style = MaterialTheme.typography.bodySmall)
                                        Button(
                                            onClick = { openWebPreview(proc.previewUrl) },
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Text("OPEN WEB PREVIEW ON DEVICE")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ==================== TAB 5: TERMINAL ====================
                "Terminal" -> {
                    Column(
                        modifier = Modifier.fillMaxSize().padding(12.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text("REMOTE TERMINAL CONSOLE", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)

                        Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            listOf("git status", "dir", "ipconfig", "npm test", "flutter test").forEach { cmd ->
                                AssistChip(
                                    onClick = { terminalInput = cmd },
                                    label = { Text(cmd, fontFamily = FontFamily.Monospace, style = MaterialTheme.typography.labelSmall) }
                                )
                            }
                        }

                        Surface(
                            modifier = Modifier.fillMaxWidth().weight(1f),
                            color = Color(0xFF121212),
                            shape = MaterialTheme.shapes.small
                        ) {
                            SelectionContainer {
                                Column(
                                    modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(10.dp)
                                ) {
                                    Text("VinhCommand Remote Console [Core: ${state.computer?.name ?: "Windows"}]", color = Color(0xFF64B5F6), fontFamily = FontFamily.Monospace, style = MaterialTheme.typography.bodySmall)
                                    Text("Working Directory: ${currentProject?.path ?: "C:\\"}\n", color = Color(0xFF9E9E9E), fontFamily = FontFamily.Monospace, style = MaterialTheme.typography.bodySmall)
                                    state.tasks.filter { it.logs.isNotEmpty() }.flatMap { it.logs }.takeLast(40).forEach { log ->
                                        Text(log, color = Color(0xFFE0E0E0), fontFamily = FontFamily.Monospace, style = MaterialTheme.typography.bodySmall)
                                    }
                                }
                            }
                        }

                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                            OutlinedTextField(
                                value = terminalInput,
                                onValueChange = { terminalInput = it },
                                placeholder = { Text("Shell command...") },
                                modifier = Modifier.weight(1f),
                                singleLine = true,
                                textStyle = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace)
                            )
                            Button(
                                onClick = {
                                    if (terminalInput.isNotBlank() && currentProject != null) {
                                        viewModel.queue(currentProject.id, state.agents.firstOrNull()?.id ?: "agent_cli", terminalInput, "workspace-write")
                                        terminalInput = ""
                                    }
                                },
                                contentPadding = PaddingValues(horizontal = 14.dp, vertical = 8.dp)
                            ) {
                                Text("Send")
                            }
                        }
                    }
                }

                // ==================== TAB 6: MORE (GITHUB, AGENTS, HARDWARE, KILL SWITCH) ====================
                "More" -> {
                    Column(
                        modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        Text("MANAGEMENT & SYSTEM CONTROLS", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)

                        // 1. GitHub Integration (Login, Download/Clone, Upload/Push)
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                    Text("GITHUB INTEGRATION", style = MaterialTheme.typography.titleSmall)
                                    Surface(
                                        color = if (isGithubLoggedIn) Color(0xFF2E7D32) else MaterialTheme.colorScheme.outlineVariant,
                                        shape = MaterialTheme.shapes.extraSmall
                                    ) {
                                        Text(
                                            if (isGithubLoggedIn) " AUTHENTICATED " else " NOT LOGGED IN ",
                                            color = if (isGithubLoggedIn) Color.White else MaterialTheme.colorScheme.onSurfaceVariant,
                                            style = MaterialTheme.typography.labelSmall,
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                        )
                                    }
                                }

                                if (!isGithubLoggedIn) {
                                    OutlinedTextField(
                                        value = githubInputUser,
                                        onValueChange = { githubInputUser = it },
                                        label = { Text("GitHub Username") },
                                        modifier = Modifier.fillMaxWidth(),
                                        singleLine = true
                                    )
                                    OutlinedTextField(
                                        value = githubInputToken,
                                        onValueChange = { githubInputToken = it },
                                        label = { Text("Personal Access Token") },
                                        placeholder = { Text("ghp_...") },
                                        modifier = Modifier.fillMaxWidth(),
                                        singleLine = true
                                    )
                                    Button(
                                        onClick = {
                                            if (githubInputUser.isNotBlank() && githubInputToken.isNotBlank()) {
                                                viewModel.loginGithub(githubInputUser, githubInputToken)
                                            }
                                        },
                                        enabled = githubInputUser.isNotBlank() && githubInputToken.isNotBlank(),
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        Text("Login to GitHub")
                                    }
                                } else {
                                    Text("Logged in as: $githubUser", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.primary)
                                }

                                HorizontalDivider()

                                Text("Download / Upload Repositories:", style = MaterialTheme.typography.labelMedium)
                                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Button(onClick = { showCloneDialog = true }, modifier = Modifier.weight(1f)) {
                                        Text("Download (Clone)")
                                    }
                                    Button(
                                        onClick = {
                                            currentProject?.let { p ->
                                                viewModel.queue(p.id, state.agents.firstOrNull()?.id ?: "agent_cli", "git push", "workspace-write")
                                            }
                                        },
                                        modifier = Modifier.weight(1f)
                                    ) {
                                        Text("Upload (Push)")
                                    }
                                }

                                OutlinedTextField(
                                    value = gitCommitMessage,
                                    onValueChange = { gitCommitMessage = it },
                                    label = { Text("Commit Message") },
                                    placeholder = { Text("Update from VinhCommand Mobile") },
                                    modifier = Modifier.fillMaxWidth(),
                                    singleLine = true
                                )
                                Button(
                                    onClick = {
                                        if (currentProject != null && gitCommitMessage.isNotBlank()) {
                                            viewModel.queue(currentProject.id, state.agents.firstOrNull()?.id ?: "agent_cli", "git commit -am \"$gitCommitMessage\"", "workspace-write")
                                            gitCommitMessage = ""
                                        }
                                    },
                                    enabled = currentProject != null && gitCommitMessage.isNotBlank(),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text("Commit Changes")
                                }
                            }
                        }

                        // 2. AI Providers Status
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                Text("AI PROVIDERS & ADAPTERS", style = MaterialTheme.typography.titleSmall)
                                Text("• Codex Desktop: Pro CLI Headless (Ready on Desktop)")
                                Text("• Antigravity Desktop: Pro Agent Engine (Ready on Desktop)")
                                Text("• GPT Online: ChatGPT Web Automation (Active)")
                                Text("• GPT Mobile: Native Mobile AI Bridge (Active)")
                                Text("• Gemini Online: Web Automation Bridge (Active)")
                                Text("• Gemini Mobile: Mobile AI Bridge (Active)")
                            }
                        }

                        // 3. System Hardware Monitor
                        Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant), modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                Text("DESKTOP HARDWARE & RUNTIME", style = MaterialTheme.typography.titleSmall)
                                Text("Device: ${state.computer?.name ?: "PC Core"}")
                                Text("OS: ${state.computer?.os ?: "Windows"}")
                                Text("LAN Bridge Port: 8444")
                                Text("Session Validity: 7 days")
                            }
                        }

                        // 4. Emergency Kill Switch
                        Card(
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Text("EMERGENCY KILL SWITCH", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.error)
                                Text("Instantly terminate all running dev servers and AI execution tasks across the connected desktop machine.", style = MaterialTheme.typography.bodySmall)
                                Button(
                                    onClick = {
                                        activeRunners.forEach { viewModel.stopRunner(it.pid) }
                                        state.tasks.filter { it.status == TaskStatus.RUNNING }.forEach { viewModel.control(it, TaskAction.STOP) }
                                    },
                                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text("STOP ALL PROCESSES IMMEDIATELY")
                                }
                            }
                        }
                    }
                }
            }

            // ==================== FLOATING CHAT BUBBLES (WHEN MINIMIZED) ====================
            Column(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(end = 16.dp, bottom = 16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
                horizontalAlignment = Alignment.End
            ) {
                // 1. AI Floating Chat Bubble
                if (isAiOverlayOpen && isAiOverlayMinimized) {
                    Surface(
                        color = Color(0xFF1B1E23),
                        shape = MaterialTheme.shapes.medium,
                        border = BorderStroke(1.dp, Color(0xFF4ADE80)),
                        shadowElevation = 8.dp
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Row(
                                modifier = Modifier
                                    .clickable { viewModel.restoreAiOverlay() }
                                    .padding(vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                Surface(color = Color(0xFF2E7D32), shape = MaterialTheme.shapes.extraSmall) {
                                    Text(" AI ", color = Color.White, style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold), modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp))
                                }
                                Text(aiResponse?.provider?.take(8)?.uppercase() ?: "REPLY", style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace), color = Color(0xFF4ADE80))
                            }
                            IconButton(
                                onClick = { viewModel.closeAiOverlay() },
                                modifier = Modifier.size(24.dp)
                            ) {
                                Text("[X]", color = Color(0xFF9EA4B0), style = MaterialTheme.typography.labelSmall)
                            }
                        }
                    }
                }

                // 2. Project IDE Floating Chat Bubble
                if (isProjectOverlayOpen && isProjectOverlayMinimized) {
                    Surface(
                        color = Color(0xFF1E2228),
                        shape = MaterialTheme.shapes.medium,
                        border = BorderStroke(1.dp, Color(0xFF4A7C59)),
                        shadowElevation = 8.dp
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Row(
                                modifier = Modifier
                                    .clickable { viewModel.restoreProjectOverlay() }
                                    .padding(vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                Surface(color = Color(0xFF1B432C), shape = MaterialTheme.shapes.extraSmall) {
                                    Text(" IDE ", color = Color(0xFF4ADE80), style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace), modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp))
                                }
                                Text(floatingProject?.name?.take(10) ?: "Project", style = MaterialTheme.typography.labelSmall, color = Color.White)
                            }
                            IconButton(
                                onClick = { viewModel.closeProjectOverlay() },
                                modifier = Modifier.size(24.dp)
                            ) {
                                Text("[X]", color = Color(0xFF9EA4B0), style = MaterialTheme.typography.labelSmall)
                            }
                        }
                    }
                }
            }

            // ==================== FLOATING PROJECT IDE WINDOW (WHEN EXPANDED) ====================
            if (isProjectOverlayOpen && !isProjectOverlayMinimized) {
                Surface(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(8.dp),
                    shape = MaterialTheme.shapes.medium,
                    color = Color(0xFF1E1E1E),
                    tonalElevation = 8.dp,
                    shadowElevation = 12.dp
                ) {
                    Column(Modifier.fillMaxSize()) {
                        // Window Title Bar
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(Color(0xFF252526))
                                .padding(horizontal = 12.dp, vertical = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(floatingProject?.name ?: "Workspace Window", style = MaterialTheme.typography.titleSmall, color = Color.White)
                                if (activeFilePath != null) {
                                    Text(
                                        "$activeFileName ${if (isFileDirty) "* (Unsaved)" else ""}",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = if (isFileDirty) Color(0xFFE57373) else Color(0xFF9CDCFE)
                                    )
                                }
                            }
                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                                if (activeFilePath != null) {
                                    Button(
                                        onClick = { viewModel.saveActiveFile() },
                                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 2.dp),
                                        colors = ButtonDefaults.buttonColors(containerColor = if (isFileDirty) Color(0xFF2E7D32) else MaterialTheme.colorScheme.primary)
                                    ) {
                                        Text("Save", style = MaterialTheme.typography.labelSmall)
                                    }
                                }
                                OutlinedButton(
                                    onClick = { viewModel.minimizeProjectOverlay() },
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                                ) {
                                    Text("[-]", color = Color.White, style = MaterialTheme.typography.labelSmall)
                                }
                                OutlinedButton(
                                    onClick = { viewModel.closeProjectOverlay() },
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                                ) {
                                    Text("[X]", color = Color.White, style = MaterialTheme.typography.labelSmall)
                                }
                            }
                        }

                        // Window Body: File Explorer or Editor
                        if (activeFilePath == null) {
                            // --- Window File Explorer (Cột nhánh cây thư mục) ---
                            Column(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .verticalScroll(rememberScrollState())
                                    .padding(10.dp),
                                verticalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                // Smart Code Runner Card (Chạy dự án trên Mobile)
                                Surface(
                                    color = Color(0xFF1E2228),
                                    shape = MaterialTheme.shapes.extraSmall,
                                    border = BorderStroke(1.dp, if (activeRunnerPid != null) Color(0xFF4ADE80) else Color(0xFF38BDF8)),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                                Text(
                                                    "CHẠY DỰ ÁN (RUN CODE):",
                                                    style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                                                    color = if (activeRunnerPid != null) Color(0xFF4ADE80) else Color.White
                                                )
                                            }
                                            if (activeRunnerPid != null) {
                                                Button(
                                                    onClick = { viewModel.stopActiveRunner() },
                                                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFEF4444)),
                                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                                                ) {
                                                    Text("Dừng PID: $activeRunnerPid", style = MaterialTheme.typography.labelSmall, color = Color.White)
                                                }
                                            }
                                        }

                                        // Action 1: If Mobile Project -> Auto download & run on phone!
                                        val isMobileProj = runnerState?.isMobile == true || fsFiles.any { it.name == "pubspec.yaml" || it.name == "build.gradle" || it.name == "AndroidManifest.xml" }
                                        if (isMobileProj) {
                                            Surface(
                                                color = Color(0xFF0F172A),
                                                shape = MaterialTheme.shapes.extraSmall,
                                                border = BorderStroke(1.dp, Color(0xFF3B82F6)),
                                                modifier = Modifier.fillMaxWidth()
                                            ) {
                                                Column(Modifier.padding(8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                                    Text(
                                                        "DỰ ÁN MOBILE (ANDROID/FLUTTER):",
                                                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                                                        color = Color(0xFF60A5FA)
                                                    )
                                                    Text("Tự động biên dịch APK trên PC và tải về máy để cài đặt chạy ngay.", style = MaterialTheme.typography.labelSmall, color = Color(0xFF94A3B8))
                                                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), modifier = Modifier.fillMaxWidth()) {
                                                        Button(
                                                            onClick = {
                                                                 floatingProject?.path?.let { p ->
                                                                    viewModel.buildApkForMobile(p) { downloadUrl, _ ->
                                                                        try {
                                                                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(downloadUrl))
                                                                            context.startActivity(intent)
                                                                        } catch (_: Exception) {}
                                                                    }
                                                                }
                                                            },
                                                            enabled = !isBuildingApk,
                                                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2563EB)),
                                                            modifier = Modifier.weight(1f),
                                                            contentPadding = PaddingValues(vertical = 4.dp)
                                                        ) {
                                                            if (isBuildingApk) {
                                                                CircularProgressIndicator(modifier = Modifier.size(14.dp), strokeWidth = 2.dp, color = Color.White)
                                                                Spacer(Modifier.width(6.dp))
                                                                Text("Đang Build APK...", style = MaterialTheme.typography.labelSmall)
                                                            } else {
                                                                Text("Tự Tải & Cài APK", style = MaterialTheme.typography.labelSmall)
                                                            }
                                                        }
                                                        OutlinedButton(
                                                            onClick = {
                                                                floatingProject?.id?.let { pid ->
                                                                    viewModel.queue(pid, "gemini-cli", "Mở trình giả lập BlueStacks trên Desktop và chạy ứng dụng mobile")
                                                                }
                                                            },
                                                            border = BorderStroke(1.dp, Color(0xFF4ADE80)),
                                                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                                                        ) {
                                                            Text("BlueStacks", color = Color(0xFF4ADE80), style = MaterialTheme.typography.labelSmall)
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // Action 2: If Web Project -> Run Web & Open on Mobile!
                                        val isWebProj = runnerState?.isWeb == true || fsFiles.any { it.name == "package.json" || it.name == "index.html" }
                                        if (isWebProj) {
                                            Surface(
                                                color = Color(0xFF0F172A),
                                                shape = MaterialTheme.shapes.extraSmall,
                                                border = BorderStroke(1.dp, Color(0xFF10B981)),
                                                modifier = Modifier.fillMaxWidth()
                                            ) {
                                                Column(Modifier.padding(8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                                    Text(
                                                        "DỰ ÁN WEB / DESKTOP (ƯU TIÊN WEB):",
                                                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                                                        color = Color(0xFF34D399)
                                                    )
                                                    Text("Khởi chạy Web Server trên PC và mở giao diện xem trên điện thoại.", style = MaterialTheme.typography.labelSmall, color = Color(0xFF94A3B8))

                                                    val webRunner = runnerState?.runners?.firstOrNull { it.previewUrl != null }
                                                    val cmd = webRunner?.command ?: "npm run dev -- --host 0.0.0.0"
                                                    val pUrl = activeWebUrl ?: webRunner?.previewUrl

                                                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), modifier = Modifier.fillMaxWidth()) {
                                                        Button(
                                                            onClick = {
                                                                floatingProject?.path?.let { p ->
                                                                    viewModel.startProjectRunner(cmd, p, webRunner?.port, webRunner?.previewUrl, openCmd = false)
                                                                }
                                                            },
                                                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF059669)),
                                                            modifier = Modifier.weight(1f),
                                                            contentPadding = PaddingValues(vertical = 4.dp)
                                                        ) {
                                                            Text(if (activeRunnerPid != null) "Đang Chạy..." else "Khởi Chạy Web", style = MaterialTheme.typography.labelSmall)
                                                        }

                                                        OutlinedButton(
                                                            onClick = {
                                                                floatingProject?.path?.let { p ->
                                                                    viewModel.startProjectRunner(cmd, p, webRunner?.port, webRunner?.previewUrl, openCmd = true)
                                                                }
                                                            },
                                                            border = BorderStroke(1.dp, Color(0xFF10B981)),
                                                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                                                        ) {
                                                            Text("Mở CMD", color = Color(0xFF34D399), style = MaterialTheme.typography.labelSmall)
                                                        }

                                                        if (pUrl != null) {
                                                            Button(
                                                                onClick = {
                                                                    try {
                                                                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(pUrl))
                                                                        context.startActivity(intent)
                                                                    } catch (_: Exception) {}
                                                                },
                                                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2563EB)),
                                                                contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                                                            ) {
                                                                Text("Mở Web >", style = MaterialTheme.typography.labelSmall)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // Action 3: Lightweight / Script Console Execution
                                        val isLight = runnerState?.isLightweight == true || fsFiles.any { it.name.endsWith(".py") || it.name.endsWith(".js") }
                                        if (isLight && !isMobileProj && !isWebProj) {
                                            Surface(
                                                color = Color(0xFF0F172A),
                                                shape = MaterialTheme.shapes.extraSmall,
                                                border = BorderStroke(1.dp, Color(0xFFEAB308)),
                                                modifier = Modifier.fillMaxWidth()
                                            ) {
                                                Column(Modifier.padding(8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                                    Text(
                                                        "DỰ ÁN NHẸ / SCRIPT / CONSOLE:",
                                                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                                                        color = Color(0xFFFACC15)
                                                    )
                                                    Text("Thực thi script trên PC và stream kết quả về điện thoại.", style = MaterialTheme.typography.labelSmall, color = Color(0xFF94A3B8))
                                                    val lightRunner = runnerState?.runners?.firstOrNull()
                                                    val cmd = lightRunner?.command ?: "python main.py"
                                                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), modifier = Modifier.fillMaxWidth()) {
                                                        Button(
                                                            onClick = {
                                                                floatingProject?.path?.let { p ->
                                                                    viewModel.startProjectRunner(cmd, p, openCmd = false)
                                                                }
                                                            },
                                                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFCA8A04)),
                                                            modifier = Modifier.weight(1f),
                                                            contentPadding = PaddingValues(vertical = 4.dp)
                                                        ) {
                                                            Text("Chạy: $cmd", style = MaterialTheme.typography.labelSmall, color = Color.White)
                                                        }

                                                        OutlinedButton(
                                                            onClick = {
                                                                floatingProject?.path?.let { p ->
                                                                    viewModel.startProjectRunner(cmd, p, openCmd = true)
                                                                }
                                                            },
                                                            border = BorderStroke(1.dp, Color(0xFFFACC15)),
                                                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                                                        ) {
                                                            Text("Mở CMD", color = Color(0xFFFACC15), style = MaterialTheme.typography.labelSmall)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Explorer Header (VS Code style)
                                Surface(
                                    color = Color(0xFF252526),
                                    shape = MaterialTheme.shapes.extraSmall,
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 6.dp),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(
                                            "EXPLORER: ${(floatingProject?.name ?: "WORKSPACE").uppercase()}",
                                            style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                                            color = Color(0xFFCCCCCC)
                                        )
                                        if (fsParentPath != null) {
                                            OutlinedButton(
                                                onClick = { viewModel.browseFs(fsParentPath) },
                                                contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp),
                                                border = BorderStroke(1.dp, Color(0xFF3E4552))
                                            ) {
                                                Text(".. [Up Folder]", style = MaterialTheme.typography.labelSmall, color = Color(0xFF4ADE80))
                                            }
                                        }
                                    }
                                }

                                val installCommands = remember(fsFiles) {
                                    val list = mutableListOf<String>()
                                    if (fsFiles.any { it.name.equals("requirements.txt", ignoreCase = true) }) list.add("pip install -r requirements.txt")
                                    if (fsFiles.any { it.name.equals("package.json", ignoreCase = true) }) list.add("npm install")
                                    if (fsFiles.any { it.name.equals("pubspec.yaml", ignoreCase = true) }) list.add("flutter pub get")
                                    if (fsFiles.any { it.name.equals("Pipfile", ignoreCase = true) }) list.add("pipenv install")
                                    if (fsFiles.any { it.name.equals("Cargo.toml", ignoreCase = true) }) list.add("cargo build")
                                    list
                                }

                                if (installCommands.isNotEmpty()) {
                                    Surface(
                                        color = Color(0xFF1E293B),
                                        shape = MaterialTheme.shapes.extraSmall,
                                        border = BorderStroke(1.dp, Color(0xFF3B82F6)),
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                            Text(
                                                "TÀI NGUYÊN CẦN THIẾT (${installCommands.size} LỆNH):",
                                                style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                                                color = Color(0xFF60A5FA)
                                            )
                                            installCommands.forEach { cmd ->
                                                Text("> $cmd", style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace), color = Color(0xFFE2E8F0))
                                            }
                                            Button(
                                                onClick = {
                                                    floatingProject?.id?.let { pid ->
                                                        viewModel.queue(pid, "gemini-cli", "Tự động cài đặt tài nguyên dự án: ${installCommands.joinToString(" && ")}")
                                                    }
                                                },
                                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2563EB)),
                                                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                                modifier = Modifier.fillMaxWidth().padding(top = 4.dp)
                                            ) {
                                                Text("Tải tài nguyên (Chạy trên PC)", style = MaterialTheme.typography.labelSmall, color = Color.White)
                                            }
                                        }
                                    }
                                }

                                if (fsCurrentPath.isNotBlank()) {
                                    Text(
                                        fsCurrentPath.replace("\\", " > "),
                                        style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace),
                                        color = Color(0xFF858585),
                                        modifier = Modifier.padding(horizontal = 4.dp)
                                    )
                                }

                                if (fsLoading) LinearProgressIndicator(modifier = Modifier.fillMaxWidth(), color = Color(0xFF4ADE80))

                                // Folder branch items
                                fsFolders.forEach { f ->
                                    Surface(
                                        color = Color(0xFF252526),
                                        shape = MaterialTheme.shapes.extraSmall,
                                        border = BorderStroke(1.dp, Color(0xFF2D2D30)),
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .clickable { viewModel.browseFs(f.path) }
                                    ) {
                                        Row(
                                            modifier = Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 8.dp),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                                Text("[DIR]", color = Color(0xFFDCDCAA), style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold))
                                                Text(f.name, style = MaterialTheme.typography.bodyMedium, color = Color(0xFFE2E4E9))
                                            }
                                            Text("Open >", color = Color(0xFF858585), style = MaterialTheme.typography.labelSmall)
                                        }
                                    }
                                }

                                // File branch items
                                fsFiles.forEach { file ->
                                    val ext = file.extension.lowercase()
                                    val fileColor = when (ext) {
                                        "dart" -> Color(0xFF40C4FF)
                                        "py" -> Color(0xFFFFD54F)
                                        "js", "jsx" -> Color(0xFFFFCA28)
                                        "ts", "tsx" -> Color(0xFF42A5F5)
                                        "json" -> Color(0xFFFFF176)
                                        "html" -> Color(0xFFFF7043)
                                        "css" -> Color(0xFF29B6F6)
                                        "md" -> Color(0xFF81D4FA)
                                        else -> Color(0xFF90A4AE)
                                    }
                                    Surface(
                                        color = Color(0xFF1E1E1E),
                                        shape = MaterialTheme.shapes.extraSmall,
                                        border = BorderStroke(1.dp, Color(0xFF2D2D30)),
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .clickable { viewModel.openFile(file.path) }
                                    ) {
                                        Row(
                                            modifier = Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 8.dp),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.weight(1f)) {
                                                Text("•", color = fileColor, style = MaterialTheme.typography.bodyLarge)
                                                Column {
                                                    Text(file.name, style = MaterialTheme.typography.bodyMedium.copy(fontFamily = FontFamily.Monospace), color = Color(0xFFCCCCCC))
                                                    Text("${file.sizeBytes / 1024} KB · ${file.extension.uppercase()}", style = MaterialTheme.typography.labelSmall, color = Color(0xFF858585))
                                                }
                                            }
                                            OutlinedButton(
                                                onClick = { viewModel.openFile(file.path) },
                                                contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp),
                                                border = BorderStroke(1.dp, Color(0xFF007ACC))
                                            ) {
                                                Text("Edit", color = Color(0xFF007ACC), style = MaterialTheme.typography.labelSmall)
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            // --- Window Code Editor (Giao diện Visual Studio) ---
                            Column(modifier = Modifier.fillMaxSize()) {
                                // VS Tab Header Bar
                                Surface(
                                    color = Color(0xFF252526),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                            OutlinedButton(
                                                onClick = { viewModel.closeActiveFile() },
                                                contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp),
                                                border = BorderStroke(1.dp, Color(0xFF3E4552))
                                            ) {
                                                Text("< Files", style = MaterialTheme.typography.labelSmall, color = Color(0xFFE2E4E9))
                                            }
                                            Surface(
                                                color = Color(0xFF1E1E1E),
                                                shape = MaterialTheme.shapes.extraSmall,
                                                border = BorderStroke(1.dp, Color(0xFF007ACC))
                                            ) {
                                                Row(modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                                                    Text(activeFileName, style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold), color = Color.White)
                                                    if (isFileDirty) {
                                                        Text(" ●", color = Color(0xFF007ACC), style = MaterialTheme.typography.labelSmall)
                                                    }
                                                }
                                            }
                                        }

                                        Button(
                                            onClick = { viewModel.saveActiveFile() },
                                            enabled = isFileDirty,
                                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                            colors = ButtonDefaults.buttonColors(
                                                containerColor = if (isFileDirty) Color(0xFF007ACC) else Color(0xFF2D2D30),
                                                disabledContainerColor = Color(0xFF2D2D30)
                                            )
                                        ) {
                                            Text("Save to PC", style = MaterialTheme.typography.labelSmall, color = Color.White)
                                        }
                                    }
                                }

                                // VS Breadcrumbs Bar
                                Surface(
                                    color = Color(0xFF1E1E1E),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text(
                                        (activeFilePath ?: "").replace("\\", " > "),
                                        style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace),
                                        color = Color(0xFF858585),
                                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 2.dp),
                                        maxLines = 1
                                    )
                                }

                                // Quick Symbol Toolbar
                                Row(
                                    Modifier
                                        .fillMaxWidth()
                                        .background(Color(0xFF22262C))
                                        .horizontalScroll(rememberScrollState())
                                        .padding(horizontal = 6.dp, vertical = 3.dp),
                                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    listOf("Tab", "{", "}", "(", ")", ";", "->", "=", "\"", "'", "[]", "//", ":", "_").forEach { sym ->
                                        OutlinedButton(
                                            onClick = {
                                                val insertion = if (sym == "Tab") "    " else sym
                                                viewModel.updateFileContent(activeFileContent + insertion)
                                            },
                                            contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp),
                                            border = BorderStroke(1.dp, Color(0xFF3E4552))
                                        ) {
                                            Text(sym, fontFamily = FontFamily.Monospace, style = MaterialTheme.typography.labelSmall, color = Color(0xFFD4D4D4))
                                        }
                                    }
                                }

                                if (fileLoading) LinearProgressIndicator(modifier = Modifier.fillMaxWidth(), color = Color(0xFF007ACC))

                                // VS Code Canvas with Line Numbers Gutter
                                val lineCount = remember(activeFileContent) { activeFileContent.lines().size.coerceAtLeast(1) }
                                Row(
                                    modifier = Modifier
                                        .weight(1f)
                                        .fillMaxWidth()
                                        .background(Color(0xFF1E1E1E))
                                ) {
                                    // Line numbers column
                                    Surface(
                                        color = Color(0xFF1E1E1E),
                                        border = BorderStroke(1.dp, Color(0xFF2D2D30)),
                                        modifier = Modifier.width(36.dp).fillMaxHeight()
                                    ) {
                                        Text(
                                            (1..lineCount).joinToString("\n"),
                                            style = MaterialTheme.typography.bodySmall.copy(
                                                fontFamily = FontFamily.Monospace,
                                                color = Color(0xFF858585),
                                                lineHeight = 20.sp,
                                                textAlign = androidx.compose.ui.text.style.TextAlign.End
                                            ),
                                            modifier = Modifier.padding(top = 8.dp, end = 4.dp)
                                        )
                                    }

                                    // Editable code field
                                    OutlinedTextField(
                                        value = activeFileContent,
                                        onValueChange = { viewModel.updateFileContent(it) },
                                        modifier = Modifier.fillMaxSize().padding(horizontal = 4.dp),
                                        textStyle = MaterialTheme.typography.bodySmall.copy(
                                            fontFamily = FontFamily.Monospace,
                                            color = Color(0xFFD4D4D4),
                                            lineHeight = 20.sp
                                        ),
                                        colors = OutlinedTextFieldDefaults.colors(
                                            focusedContainerColor = Color(0xFF1E1E1E),
                                            unfocusedContainerColor = Color(0xFF1E1E1E),
                                            focusedBorderColor = Color.Transparent,
                                            unfocusedBorderColor = Color.Transparent
                                        )
                                    )
                                }

                                // VS Code Bottom Status Bar
                                Surface(
                                    color = Color(0xFF007ACC),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 2.dp),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text("Lines: $lineCount · Spaces: 4 · UTF-8", style = MaterialTheme.typography.labelSmall, color = Color.White)
                                        Text(activeFileName.split('.').lastOrNull()?.uppercase() ?: "CODE", style = MaterialTheme.typography.labelSmall.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold), color = Color.White)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==================== FLOATING AI & MASTER TASK OVERLAY WINDOW (WHEN EXPANDED) ====================
            if (isAiOverlayOpen && !isAiOverlayMinimized) {
                val currentProjectMasterTask = remember(state.tasks, currentProject?.id) {
                    state.tasks.firstOrNull { it.id == "master_${currentProject?.id}" }
                        ?: state.tasks.firstOrNull { it.projectId == currentProject?.id }
                }
                var overlayTab by remember { mutableStateOf("chat") } // "chat" or "code"

                Surface(
                    modifier = Modifier
                        .fillMaxSize(),
                    color = Color(0xFF161B22),
                    tonalElevation = 8.dp,
                    shadowElevation = 16.dp
                ) {
                    Column(Modifier.fillMaxSize()) {
                        // Window Title Bar with Tab Switching
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(Color(0xFF1E2228))
                                .padding(horizontal = 12.dp, vertical = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                Surface(color = Color(0xFF2E7D32), shape = MaterialTheme.shapes.extraSmall) {
                                    Text(
                                        " TASK TỔNG ",
                                        color = Color.White,
                                        style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                    )
                                }
                                Text(
                                    currentProject?.name ?: "Project Workspace",
                                    style = MaterialTheme.typography.titleSmall.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                                    color = Color(0xFF4ADE80)
                                )
                            }

                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                                FilterChip(
                                    selected = overlayTab == "chat",
                                    onClick = { overlayTab = "chat" },
                                    label = { Text("Chat AI", style = MaterialTheme.typography.labelSmall) },
                                    colors = FilterChipDefaults.filterChipColors(
                                        selectedContainerColor = Color(0xFF386345),
                                        selectedLabelColor = Color.White,
                                        containerColor = Color(0xFF1B1E23),
                                        labelColor = Color(0xFFE2E4E9)
                                    ),
                                    border = BorderStroke(1.dp, if (overlayTab == "chat") Color(0xFF4ADE80) else Color(0xFF3E4552))
                                )
                                FilterChip(
                                    selected = overlayTab == "code",
                                    onClick = {
                                        overlayTab = "code"
                                        if (fsCurrentPath.isBlank() && currentProject != null) {
                                            viewModel.browseFs(currentProject.path)
                                        }
                                    },
                                    label = { Text("Sửa Code (VS)", style = MaterialTheme.typography.labelSmall) },
                                    colors = FilterChipDefaults.filterChipColors(
                                        selectedContainerColor = Color(0xFF005A9E),
                                        selectedLabelColor = Color.White,
                                        containerColor = Color(0xFF1B1E23),
                                        labelColor = Color(0xFFE2E4E9)
                                    ),
                                    border = BorderStroke(1.dp, if (overlayTab == "code") Color(0xFF007ACC) else Color(0xFF3E4552))
                                )

                                OutlinedButton(
                                    onClick = { viewModel.minimizeAiOverlay() },
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp),
                                    border = BorderStroke(1.dp, Color(0xFF3E4552))
                                ) {
                                    Text("[-]", color = Color(0xFFE2E4E9), style = MaterialTheme.typography.labelSmall)
                                }
                                OutlinedButton(
                                    onClick = { viewModel.closeAiOverlay() },
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp),
                                    border = BorderStroke(1.dp, Color(0xFF3E4552))
                                ) {
                                    Text("[X]", color = Color(0xFFE2E4E9), style = MaterialTheme.typography.labelSmall)
                                }
                            }
                        }

                        if (overlayTab == "chat") {
                            // ==================== TAB 1: LỊCH SỬ CHAT AI ====================
                            Column(
                                modifier = Modifier
                                    .weight(1f)
                                    .verticalScroll(rememberScrollState())
                                    .padding(12.dp),
                                verticalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                // Project Header
                                Card(colors = CardDefaults.cardColors(containerColor = Color(0xFF22262C)), border = BorderStroke(1.dp, Color(0xFF3E4552))) {
                                    Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                            Text("DỰ ÁN: ${currentProject?.name ?: "Workspace"}", style = MaterialTheme.typography.labelMedium.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold), color = Color(0xFF4ADE80))
                                            Text("Loại: ${currentProject?.framework ?: "Project"}", style = MaterialTheme.typography.labelSmall, color = Color(0xFF9EA4B0))
                                        }
                                        SelectionContainer {
                                            Text("Đường dẫn PC: ${currentProject?.path ?: ""}", style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace), color = Color(0xFF727885))
                                        }
                                    }
                                }

                                Text("LỊCH SỬ TƯƠNG TÁC & CHAT AI:", style = MaterialTheme.typography.labelMedium.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold), color = Color(0xFF4ADE80))

                                // Master Task Logs from Desktop (Without Duplicate & Clean Senders)
                                val taskLogs = currentProjectMasterTask?.logs ?: emptyList()
                                if (taskLogs.isNotEmpty()) {
                                    taskLogs.forEach { logMessage ->
                                        val isUser = logMessage.startsWith("👤") || logMessage.startsWith("[User]") || logMessage.startsWith("User:")
                                        val cleanText = logMessage
                                            .replace(Regex("^[👤🤖\\s]*\\[(User|Agent|[^\\]]+)\\]:\\s*"), "")
                                            .trim()
                                        Card(
                                            modifier = Modifier.fillMaxWidth(),
                                            colors = CardDefaults.cardColors(
                                                containerColor = if (isUser) Color(0xFF1E2D24) else Color(0xFF1B232E)
                                            ),
                                            border = BorderStroke(1.dp, if (isUser) Color(0xFF386345) else Color(0xFF2E4057))
                                        ) {
                                            Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                                Text(
                                                    if (isUser) "BẠN (USER):" else "AI DESKTOP:",
                                                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                                                    color = if (isUser) Color(0xFF4ADE80) else Color(0xFF64B5F6)
                                                )
                                                SelectionContainer {
                                                    Text(
                                                        cleanText,
                                                        style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace, lineHeight = 18.sp),
                                                        color = Color(0xFFE2E4E9)
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }

                                // Active AI Response (Only shown if NOT already present in logs)
                                val isResponseAlreadyInLogs = remember(taskLogs, aiResponse) {
                                    aiResponse?.let { resp ->
                                        taskLogs.any { it.contains(resp.reply.take(30).trim()) }
                                    } ?: false
                                }

                                if (aiResponse != null && !isResponseAlreadyInLogs) {
                                    val resp = aiResponse!!
                                    Card(
                                        modifier = Modifier.fillMaxWidth(),
                                        colors = CardDefaults.cardColors(containerColor = Color(0xFF161B22)),
                                        border = BorderStroke(1.dp, Color(0xFF4A7C59))
                                    ) {
                                        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                            Text("PHẢN HỒI TỪ ${resp.provider.uppercase()}:", style = MaterialTheme.typography.labelMedium.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold), color = Color(0xFF4ADE80))
                                            SelectionContainer {
                                                Text(
                                                    resp.reply,
                                                    style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace, lineHeight = 20.sp),
                                                    color = Color(0xFFE2E4E9)
                                                )
                                            }
                                        }
                                    }
                                }

                                // Modified Files List
                                val modifiedFiles = aiResponse?.changedFiles ?: emptyList()
                                if (modifiedFiles.isNotEmpty()) {
                                    Text("CÁC FILE ĐÃ SỬA ĐỔI (${modifiedFiles.size}) - Bấm để mở sửa trực tiếp:", style = MaterialTheme.typography.labelSmall.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold), color = Color(0xFF4ADE80))
                                    modifiedFiles.forEach { fName ->
                                        Surface(
                                            color = Color(0xFF1E1E1E),
                                            shape = MaterialTheme.shapes.extraSmall,
                                            border = BorderStroke(1.dp, Color(0xFF007ACC)),
                                            modifier = Modifier.fillMaxWidth().clickable {
                                                val fullPath = if (fName.startsWith("/") || fName.contains(":\\")) fName else "${currentProject?.path}\\$fName"
                                                viewModel.openFile(fullPath)
                                                overlayTab = "code"
                                            }
                                        ) {
                                            Row(
                                                modifier = Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 6.dp),
                                                horizontalArrangement = Arrangement.SpaceBetween,
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Text("[FILE] $fName", style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace), color = Color(0xFF9CDCFE))
                                                Text("Sửa code (VS) >", style = MaterialTheme.typography.labelSmall.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold), color = Color(0xFF007ACC))
                                            }
                                        }
                                    }
                                }

                                // Diff Patch
                                val diffText = aiResponse?.diff ?: ""
                                if (diffText.isNotBlank()) {
                                    Text("Mã thay đổi (Diff Patch):", style = MaterialTheme.typography.labelSmall, color = Color(0xFF4ADE80))
                                    Surface(
                                        color = Color(0xFF121212),
                                        shape = MaterialTheme.shapes.extraSmall,
                                        border = BorderStroke(1.dp, Color(0xFF3E4552)),
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        SelectionContainer {
                                            Text(
                                                diffText,
                                                modifier = Modifier.padding(10.dp),
                                                style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace, color = Color(0xFF4ADE80), lineHeight = 18.sp)
                                            )
                                        }
                                    }
                                }

                                if (taskLogs.isEmpty() && aiResponse == null) {
                                    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFF22262C)), modifier = Modifier.fillMaxWidth()) {
                                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                            Text("Chưa có lịch sử chat nào cho dự án này.", style = MaterialTheme.typography.bodyMedium, color = Color(0xFFE2E4E9))
                                            Text("Hãy nhập yêu cầu bên dưới để AI phân tích, viết code và sửa trực tiếp trên máy tính!", style = MaterialTheme.typography.bodySmall, color = Color(0xFF9EA4B0))
                                        }
                                    }
                                }
                            }

                            // Follow-up Input Bar
                            Surface(
                                color = Color(0xFF1B1E23),
                                modifier = Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 6.dp),
                                border = BorderStroke(1.dp, Color(0xFF4A7C59)),
                                shape = MaterialTheme.shapes.small
                            ) {
                                Column(Modifier.padding(8.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                        Text("TIẾP TỤC HỎI / RA LỆNH CHO AI:", style = MaterialTheme.typography.labelSmall.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold), color = Color(0xFF4ADE80))
                                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                            OutlinedButton(
                                                onClick = { launchChatGPTApp(followUpPrompt.ifBlank { aiPromptText }) },
                                                contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp),
                                                border = BorderStroke(1.dp, Color(0xFF10A37F))
                                            ) {
                                                Text("ChatGPT", color = Color(0xFF10A37F), style = MaterialTheme.typography.labelSmall)
                                            }
                                            OutlinedButton(
                                                onClick = { launchGeminiApp(followUpPrompt.ifBlank { aiPromptText }) },
                                                contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp),
                                                border = BorderStroke(1.dp, Color(0xFF1A73E8))
                                            ) {
                                                Text("Gemini", color = Color(0xFF64B5F6), style = MaterialTheme.typography.labelSmall)
                                            }
                                        }
                                    }
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        OutlinedTextField(
                                            value = followUpPrompt,
                                            onValueChange = { followUpPrompt = it },
                                            placeholder = { Text("Nhập yêu cầu tiếp theo để sửa code...", style = MaterialTheme.typography.bodySmall, color = Color(0xFF727885)) },
                                            modifier = Modifier.weight(1f),
                                            maxLines = 3,
                                            textStyle = MaterialTheme.typography.bodySmall.copy(color = Color(0xFFE2E4E9)),
                                            colors = OutlinedTextFieldDefaults.colors(
                                                focusedBorderColor = Color(0xFF4A7C59),
                                                unfocusedBorderColor = Color(0xFF2B3038),
                                                focusedContainerColor = Color(0xFF161B22),
                                                unfocusedContainerColor = Color(0xFF161B22)
                                            )
                                        )
                                        Button(
                                            onClick = {
                                                if (followUpPrompt.isNotBlank() && currentProject != null) {
                                                    val pText = followUpPrompt
                                                    followUpPrompt = ""
                                                    viewModel.runAiAutomate(
                                                        provider = selectedAiProvider,
                                                        prompt = pText,
                                                        projectPath = currentProject.path,
                                                        currentFile = activeFilePath,
                                                        selectedCode = null,
                                                        mode = aiMode,
                                                        model = if (selectedAiProvider.contains("opencode")) selectedOpencodeModel else null
                                                    )
                                                }
                                            },
                                            enabled = !aiLoading && followUpPrompt.isNotBlank() && currentProject != null,
                                            colors = ButtonDefaults.buttonColors(
                                                containerColor = Color(0xFF4A7C59),
                                                disabledContainerColor = Color(0xFF2B3038)
                                            ),
                                            contentPadding = PaddingValues(horizontal = 14.dp, vertical = 8.dp)
                                        ) {
                                            Text(if (aiLoading) "..." else "Gửi AI", color = Color.White, style = MaterialTheme.typography.labelSmall)
                                        }
                                    }
                                }
                            }

                            // Bottom Bar: Apply patch or switch to code editor
                            Surface(
                                color = Color(0xFF22262C),
                                modifier = Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 6.dp)
                            ) {
                                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    if (aiResponse?.diff?.isNotBlank() == true) {
                                        Button(
                                            onClick = { viewModel.applyAiPatch() },
                                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2E7D32)),
                                            modifier = Modifier.weight(1f)
                                        ) {
                                            Text("Áp dụng bản vá lên PC", color = Color.White, style = MaterialTheme.typography.labelSmall)
                                        }
                                    }
                                    Button(
                                        onClick = {
                                            overlayTab = "code"
                                            if (fsCurrentPath.isBlank() && currentProject != null) {
                                                viewModel.browseFs(currentProject.path)
                                            }
                                        },
                                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF007ACC)),
                                        modifier = Modifier.weight(1f)
                                    ) {
                                        Text("Sửa Code Trực Tiếp (VS) >", color = Color.White, style = MaterialTheme.typography.labelSmall)
                                    }
                                }
                            }
                        } else {
                            // ==================== TAB 2: CODE EDITOR (VISUAL STUDIO DARK THEME) ====================
                            if (activeFilePath == null) {
                                // --- Project File Browser Tree ---
                                Column(
                                    modifier = Modifier
                                        .weight(1f)
                                        .verticalScroll(rememberScrollState())
                                        .padding(12.dp),
                                    verticalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(
                                            "DANH SÁCH FILE TRONG DỰ ÁN:",
                                            style = MaterialTheme.typography.labelMedium.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                                            color = Color(0xFF007ACC)
                                        )
                                        if (fsParentPath != null) {
                                            OutlinedButton(
                                                onClick = { viewModel.browseFs(fsParentPath) },
                                                contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp),
                                                border = BorderStroke(1.dp, Color(0xFF3E4552))
                                            ) {
                                                Text("[Thư mục cha]", style = MaterialTheme.typography.labelSmall, color = Color(0xFFE2E4E9))
                                            }
                                        }
                                    }

                                    Surface(
                                        color = Color(0xFF1E1E1E),
                                        modifier = Modifier.fillMaxWidth(),
                                        shape = MaterialTheme.shapes.extraSmall,
                                        border = BorderStroke(1.dp, Color(0xFF2D2D30))
                                    ) {
                                        Text(
                                            if (fsCurrentPath.isBlank()) (currentProject?.path ?: "") else fsCurrentPath,
                                            style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace),
                                            color = Color(0xFF9EA4B0),
                                            modifier = Modifier.padding(8.dp)
                                        )
                                    }

                                    if (fsLoading) LinearProgressIndicator(modifier = Modifier.fillMaxWidth(), color = Color(0xFF007ACC))

                                    // Folders
                                    fsFolders.forEach { folder ->
                                        Card(
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .clickable { viewModel.browseFs(folder.path) },
                                            colors = CardDefaults.cardColors(containerColor = Color(0xFF252526)),
                                            border = BorderStroke(1.dp, Color(0xFF2D2D30))
                                        ) {
                                            Row(
                                                modifier = Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 8.dp),
                                                horizontalArrangement = Arrangement.SpaceBetween,
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                                    Text("[DIR]", color = Color(0xFFDCDCAA), style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold))
                                                    Text(folder.name, style = MaterialTheme.typography.bodySmall.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold), color = Color(0xFFD4D4D4))
                                                }
                                                Text(">", color = Color(0xFF858585), style = MaterialTheme.typography.labelSmall)
                                            }
                                        }
                                    }

                                    // Files
                                    fsFiles.forEach { fileItem ->
                                        val ext = fileItem.name.substringAfterLast('.', "").lowercase()
                                        val fileColor = when (ext) {
                                            "dart" -> Color(0xFF40C4FF)
                                            "py" -> Color(0xFFFFD54F)
                                            "js", "jsx" -> Color(0xFFFFCA28)
                                            "ts", "tsx" -> Color(0xFF42A5F5)
                                            "json" -> Color(0xFFFFF176)
                                            "html" -> Color(0xFFFF7043)
                                            "css" -> Color(0xFF29B6F6)
                                            "md" -> Color(0xFF81D4FA)
                                            else -> Color(0xFF9CDCFE)
                                        }
                                        Card(
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .clickable { viewModel.openFile(fileItem.path) },
                                            colors = CardDefaults.cardColors(containerColor = Color(0xFF1E1E1E)),
                                            border = BorderStroke(1.dp, Color(0xFF2D2D30))
                                        ) {
                                            Row(
                                                modifier = Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 8.dp),
                                                horizontalArrangement = Arrangement.SpaceBetween,
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                                    Text("[FILE]", color = Color(0xFF9EA4B0), style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace))
                                                    Text(fileItem.name, style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace), color = fileColor)
                                                }
                                                Button(
                                                    onClick = { viewModel.openFile(fileItem.path) },
                                                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 2.dp),
                                                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF007ACC))
                                                ) {
                                                    Text("Sửa", color = Color.White, style = MaterialTheme.typography.labelSmall)
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                // --- Visual Studio Dark Code Canvas with Save to PC ---
                                Column(modifier = Modifier.fillMaxSize()) {
                                    // Header: File tab & SAVE TO PC button
                                    Surface(
                                        color = Color(0xFF252526),
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        Row(
                                            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                                OutlinedButton(
                                                    onClick = { viewModel.closeActiveFile() },
                                                    contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp),
                                                    border = BorderStroke(1.dp, Color(0xFF3E4552))
                                                ) {
                                                    Text("< File khác", style = MaterialTheme.typography.labelSmall, color = Color(0xFFE2E4E9))
                                                }
                                                Surface(
                                                    color = Color(0xFF1E1E1E),
                                                    shape = MaterialTheme.shapes.extraSmall,
                                                    border = BorderStroke(1.dp, Color(0xFF007ACC))
                                                ) {
                                                    Row(modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                                                        Text(activeFileName, style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace, fontWeight = androidx.compose.ui.text.font.FontWeight.Bold), color = Color.White)
                                                        if (isFileDirty) {
                                                            Text(" ●", color = Color(0xFF007ACC), style = MaterialTheme.typography.labelSmall)
                                                        }
                                                    }
                                                }
                                            }

                                            // Prominent Save to Desktop Button
                                            Button(
                                                onClick = { viewModel.saveActiveFile() },
                                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                                                colors = ButtonDefaults.buttonColors(
                                                    containerColor = if (isFileDirty) Color(0xFF007ACC) else Color(0xFF2E7D32)
                                                )
                                            ) {
                                                Text(
                                                    if (isFileDirty) "LƯU LÊN PC *" else "ĐÃ LƯU TRÊN PC",
                                                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                                                    color = Color.White
                                                )
                                            }
                                        }
                                    }

                                    // Breadcrumbs Bar
                                    Surface(
                                        color = Color(0xFF1E1E1E),
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        Text(
                                            (activeFilePath ?: "").replace("\\", " > "),
                                            style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace),
                                            color = Color(0xFF858585),
                                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 2.dp),
                                            maxLines = 1
                                        )
                                    }

                                    // Quick Symbol Toolbar
                                    Row(
                                        Modifier
                                            .fillMaxWidth()
                                            .background(Color(0xFF22262C))
                                            .horizontalScroll(rememberScrollState())
                                            .padding(horizontal = 6.dp, vertical = 3.dp),
                                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                                    ) {
                                        listOf("Tab", "{", "}", "(", ")", ";", "->", "=", "\"", "'", "[]", "//", ":", "_").forEach { sym ->
                                            OutlinedButton(
                                                onClick = {
                                                    val insertion = if (sym == "Tab") "    " else sym
                                                    viewModel.updateFileContent(activeFileContent + insertion)
                                                },
                                                contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp),
                                                border = BorderStroke(1.dp, Color(0xFF3E4552))
                                            ) {
                                                Text(sym, fontFamily = FontFamily.Monospace, style = MaterialTheme.typography.labelSmall, color = Color(0xFFD4D4D4))
                                            }
                                        }
                                    }

                                    if (fileLoading) LinearProgressIndicator(modifier = Modifier.fillMaxWidth(), color = Color(0xFF007ACC))

                                    // VS Code Canvas with Line Numbers Gutter
                                    val lineCount = remember(activeFileContent) { activeFileContent.lines().size.coerceAtLeast(1) }
                                    Row(
                                        modifier = Modifier
                                            .weight(1f)
                                            .fillMaxWidth()
                                            .background(Color(0xFF1E1E1E))
                                    ) {
                                        // Line numbers column
                                        Surface(
                                            color = Color(0xFF1E1E1E),
                                            border = BorderStroke(1.dp, Color(0xFF2D2D30)),
                                            modifier = Modifier.width(36.dp).fillMaxHeight()
                                        ) {
                                            Text(
                                                (1..lineCount).joinToString("\n"),
                                                style = MaterialTheme.typography.bodySmall.copy(
                                                    fontFamily = FontFamily.Monospace,
                                                    color = Color(0xFF858585),
                                                    lineHeight = 20.sp,
                                                    textAlign = androidx.compose.ui.text.style.TextAlign.End
                                                ),
                                                modifier = Modifier.padding(top = 8.dp, end = 4.dp)
                                            )
                                        }

                                        // Editable code field
                                        OutlinedTextField(
                                            value = activeFileContent,
                                            onValueChange = { viewModel.updateFileContent(it) },
                                            modifier = Modifier.fillMaxSize().padding(horizontal = 4.dp),
                                            textStyle = MaterialTheme.typography.bodySmall.copy(
                                                fontFamily = FontFamily.Monospace,
                                                color = Color(0xFFD4D4D4),
                                                lineHeight = 20.sp
                                            ),
                                            colors = OutlinedTextFieldDefaults.colors(
                                                focusedContainerColor = Color(0xFF1E1E1E),
                                                unfocusedContainerColor = Color(0xFF1E1E1E),
                                                focusedBorderColor = Color.Transparent,
                                                unfocusedBorderColor = Color.Transparent
                                            )
                                        )
                                    }

                                    // VS Code Bottom Status Bar
                                    Surface(
                                        color = Color(0xFF007ACC),
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        Row(
                                            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 2.dp),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Text("Lines: $lineCount · Spaces: 4 · UTF-8", style = MaterialTheme.typography.labelSmall, color = Color.White)
                                            Text(activeFileName.split('.').lastOrNull()?.uppercase() ?: "CODE", style = MaterialTheme.typography.labelSmall.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold), color = Color.White)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

