package com.vinhcommand.presentation.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.ConnectionRepository
import com.vinhcommand.domain.repository.TaskRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

import com.vinhcommand.network.api.VinhCommandApi

@HiltViewModel
class CompanionViewModel @Inject constructor(
    private val connection: ConnectionRepository,
    private val tasks: TaskRepository,
    private val api: VinhCommandApi
) : ViewModel() {
    val state = connection.pcStateFlow.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), PcState())
    val connectionState = connection.connectionStateFlow.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), ConnectionState.DISCONNECTED)
    private val _message = MutableStateFlow<String?>(null)
    val message = _message.asStateFlow()
    private val _busy = MutableStateFlow(false)
    val busy = _busy.asStateFlow()

    init {
        fetchOpencodeModels()
    }

    fun queue(projectId: String, agentId: String, prompt: String, permission: String = "read-only", parentTaskId: String? = null) {
        if(_busy.value) return
        if(prompt.isBlank() || prompt.length > 20000) { _message.value = "Enter a prompt between 1 and 20000 characters"; return }
        viewModelScope.launch {
            _busy.value = true
            try {
                tasks.createTask(CreateTaskRequest("Mobile review", agentId, projectId, prompt.trim(), false, 1, false, false, permission, parentTaskId))
                    .onSuccess { _message.value = "Task queued. Confirm Run on desktop or on this phone if controls are enabled." }
                    .onFailure { _message.value = it.message ?: "Could not queue task" }
            } finally { _busy.value = false }
        }
    }
    fun control(task: AgentTask, action: TaskAction) {
        viewModelScope.launch {
            tasks.controlTask(TaskControlRequest(task.id, action, task.workflow.approval?.id))
                .onSuccess { _message.value = "Action sent. Waiting for desktop state." }
                .onFailure { _message.value = it.message ?: "Action failed" }
        }
    }
    fun deleteProject(projectId: String) {
        viewModelScope.launch {
            try {
                val res = api.deleteProject(mapOf("projectId" to projectId))
                if (res.isSuccessful) {
                    _message.value = "Project removed"
                } else {
                    _message.value = "Could not remove project (${res.code()})"
                }
            } catch (e: Exception) {
                _message.value = e.message ?: "Could not remove project"
            }
        }
    }
    fun clearAllProjects() {
        viewModelScope.launch {
            try {
                val res = api.deleteProject(mapOf("clearAll" to "true"))
                if (res.isSuccessful) {
                    _message.value = "All projects cleared"
                } else {
                    _message.value = "Could not clear projects (${res.code()})"
                }
            } catch (e: Exception) {
                _message.value = e.message ?: "Could not clear projects"
            }
        }
    }

    private val _fsCurrentPath = MutableStateFlow("")
    val fsCurrentPath = _fsCurrentPath.asStateFlow()

    private val _fsParentPath = MutableStateFlow<String?>(null)
    val fsParentPath = _fsParentPath.asStateFlow()

    private val _fsFolders = MutableStateFlow<List<com.vinhcommand.network.model.FsFolderItem>>(emptyList())
    val fsFolders = _fsFolders.asStateFlow()

    private val _fsLoading = MutableStateFlow(false)
    val fsLoading = _fsLoading.asStateFlow()

    private val _fsFiles = MutableStateFlow<List<com.vinhcommand.network.model.FsFileItem>>(emptyList())
    val fsFiles = _fsFiles.asStateFlow()

    fun browseFs(path: String? = null) {
        viewModelScope.launch {
            _fsLoading.value = true
            try {
                val res = api.browseDesktopFs(path)
                val data = res.body()?.data
                if (res.isSuccessful && data != null) {
                    _fsCurrentPath.value = data.currentPath
                    _fsParentPath.value = data.parentPath
                    _fsFolders.value = data.folders
                    _fsFiles.value = data.files
                } else {
                    _message.value = res.body()?.error?.message ?: "Unable to browse desktop directory"
                }
            } catch (e: Exception) {
                _message.value = e.message ?: "Error browsing desktop directory"
            } finally {
                _fsLoading.value = false
            }
        }
    }

    // --- IDE & Code Editor ---
    private val _activeFilePath = MutableStateFlow<String?>(null)
    val activeFilePath = _activeFilePath.asStateFlow()

    private val _activeFileName = MutableStateFlow("")
    val activeFileName = _activeFileName.asStateFlow()

    private val _activeFileContent = MutableStateFlow("")
    val activeFileContent = _activeFileContent.asStateFlow()

    private val _originalFileContent = MutableStateFlow("")
    val isFileDirty = MutableStateFlow(false)

    private val _fileLoading = MutableStateFlow(false)
    val fileLoading = _fileLoading.asStateFlow()

    fun openFile(path: String) {
        viewModelScope.launch {
            _fileLoading.value = true
            try {
                val res = api.readFile(path)
                val data = res.body()?.data
                if (res.isSuccessful && data != null) {
                    _activeFilePath.value = data.path
                    _activeFileName.value = data.name ?: path.split('\\', '/').last()
                    _activeFileContent.value = data.content
                    _originalFileContent.value = data.content
                    isFileDirty.value = false
                    _message.value = "Opened file: ${_activeFileName.value}"
                } else {
                    _message.value = "Unable to open file: ${res.code()}"
                }
            } catch (e: Exception) {
                _message.value = "Error reading file: ${e.message}"
            } finally {
                _fileLoading.value = false
            }
        }
    }

    fun updateFileContent(newText: String) {
        _activeFileContent.value = newText
        isFileDirty.value = newText != _originalFileContent.value
    }

    fun saveActiveFile() {
        val path = _activeFilePath.value ?: return
        viewModelScope.launch {
            _fileLoading.value = true
            try {
                val res = api.writeFile(com.vinhcommand.network.model.FileWriteRequest(path, _activeFileContent.value))
                if (res.isSuccessful && res.body()?.success == true) {
                    _originalFileContent.value = _activeFileContent.value
                    isFileDirty.value = false
                    _message.value = "Đã lưu thay đổi lên máy tính Desktop thành công!"
                    connection.refreshPcState()
                } else {
                    _message.value = "Lỗi khi lưu file: ${res.code()}"
                }
            } catch (e: Exception) {
                _message.value = "Lỗi khi lưu file: ${e.message}"
            } finally {
                _fileLoading.value = false
            }
        }
    }

    fun closeActiveFile() {
        _activeFilePath.value = null
        _activeFileName.value = ""
        _activeFileContent.value = ""
        _originalFileContent.value = ""
        isFileDirty.value = false
    }

    // --- Run Center ---
    private val _detectedRunners = MutableStateFlow<List<com.vinhcommand.network.model.RunnerItem>>(emptyList())
    val detectedRunners = _detectedRunners.asStateFlow()

    private val _activeRunners = MutableStateFlow<List<com.vinhcommand.network.model.ActiveRunnerItem>>(emptyList())
    val activeRunners = _activeRunners.asStateFlow()

    private val _runnerFramework = MutableStateFlow("Custom")
    val runnerFramework = _runnerFramework.asStateFlow()

    private val _runnerLoading = MutableStateFlow(false)
    val runnerLoading = _runnerLoading.asStateFlow()

    fun detectRunners(projectPath: String) {
        viewModelScope.launch {
            _runnerLoading.value = true
            try {
                val res = api.detectRunners(projectPath)
                val data = res.body()?.data
                if (res.isSuccessful && data != null) {
                    _runnerFramework.value = data.framework
                    _detectedRunners.value = data.runners
                }
            } catch (e: Exception) {
                // ignore
            } finally {
                _runnerLoading.value = false
            }
        }
    }

    fun startRunner(command: String, cwd: String, port: Int = 5173, openCmd: Boolean = false, onStarted: (String?) -> Unit = {}) {
        viewModelScope.launch {
            _runnerLoading.value = true
            try {
                val body = mutableMapOf(
                    "command" to command,
                    "cwd" to cwd,
                    "port" to port.toString()
                )
                if (openCmd) {
                    body["openCmd"] = "true"
                }
                val res = api.startRunner(body)
                val data = res.body()?.data
                if (res.isSuccessful && data != null && data.success) {
                    _message.value = if (openCmd) "Đã mở tiến trình trên cửa sổ CMD máy tính!" else "Đang chạy: $command (Port: ${data.port ?: port})"
                    refreshRunners()
                    onStarted(data.previewUrl)
                } else {
                    _message.value = "Failed to start: ${res.code()}"
                }
            } catch (e: Exception) {
                _message.value = "Error: ${e.message}"
            } finally {
                _runnerLoading.value = false
            }
        }
    }

    fun stopRunner(pid: Int) {
        viewModelScope.launch {
            try {
                api.stopRunner(mapOf("pid" to pid))
                refreshRunners()
                _message.value = "Stopped process #$pid"
            } catch (e: Exception) {
                _message.value = "Failed to stop process: ${e.message}"
            }
        }
    }

    fun refreshRunners() {
        viewModelScope.launch {
            try {
                val res = api.listRunners()
                val data = res.body()?.data
                if (res.isSuccessful && data != null) {
                    _activeRunners.value = data.runners
                }
            } catch (_: Exception) {}
        }
    }

    // --- AI Automation Bridge (No Copy/Paste) ---
    private val _aiResponse = MutableStateFlow<com.vinhcommand.network.model.AiAutomateResponse?>(null)
    val aiResponse = _aiResponse.asStateFlow()

    private val _aiLoading = MutableStateFlow(false)
    val aiLoading = _aiLoading.asStateFlow()

    private val _isAiOverlayOpen = MutableStateFlow(false)
    val isAiOverlayOpen = _isAiOverlayOpen.asStateFlow()

    private val _isAiOverlayMinimized = MutableStateFlow(false)
    val isAiOverlayMinimized = _isAiOverlayMinimized.asStateFlow()

    fun openAiOverlay() {
        _isAiOverlayOpen.value = true
        _isAiOverlayMinimized.value = false
    }

    fun minimizeAiOverlay() {
        _isAiOverlayMinimized.value = true
    }

    fun restoreAiOverlay() {
        _isAiOverlayMinimized.value = false
    }

    fun closeAiOverlay() {
        _isAiOverlayOpen.value = false
        _isAiOverlayMinimized.value = false
    }

    // --- OpenCode Models State ---
    private val _opencodeProviders = MutableStateFlow<List<com.vinhcommand.network.model.OpencodeProviderDto>>(
        listOf(
            com.vinhcommand.network.model.OpencodeProviderDto("zenmux", "ZenMux", "ZenMux Aggregator (Free & High-Performance Models)", true),
            com.vinhcommand.network.model.OpencodeProviderDto("kilo", "Kilo Gateway", "Kilo AI Gateway (Diverse Free Models)", true),
            com.vinhcommand.network.model.OpencodeProviderDto("opencode", "OpenCode Zen", "OpenCode Official Free Coding Models", true)
        )
    )
    val opencodeProviders = _opencodeProviders.asStateFlow()

    private val _opencodeModels = MutableStateFlow<List<com.vinhcommand.network.model.OpencodeModelDto>>(
        listOf(
            // ZenMux - Free models first
            com.vinhcommand.network.model.OpencodeModelDto("zenmux/z-ai/glm-4.6v-flash-free", "zenmux", "GLM-4.6v Flash (Free)", true, "Ultra-fast vision & code generation"),
            com.vinhcommand.network.model.OpencodeModelDto("zenmux/z-ai/glm-4.7-flash-free", "zenmux", "GLM-4.7 Flash (Free)", true, "Next-gen fast code generation"),
            com.vinhcommand.network.model.OpencodeModelDto("zenmux/z-ai/glm-5.2-free", "zenmux", "GLM-5.2 (Free)", true, "High-capability reasoning"),
            com.vinhcommand.network.model.OpencodeModelDto("zenmux/moonshotai/kimi-k3-free", "zenmux", "Kimi K3 (Free)", true, "Moonshot long-context reasoning"),
            com.vinhcommand.network.model.OpencodeModelDto("zenmux/moonshotai/kimi-k2.7-code-free", "zenmux", "Kimi K2.7 Code (Free)", true, "Specialized for code refactoring"),
            com.vinhcommand.network.model.OpencodeModelDto("zenmux/stepfun/step-3.7-flash-free", "zenmux", "Step 3.7 Flash (Free)", true, "High-efficiency fast code model"),
            com.vinhcommand.network.model.OpencodeModelDto("zenmux/anthropic/claude-sonnet-5-free", "zenmux", "Claude Sonnet 5 (Free)", true, "State of the art reasoning"),
            com.vinhcommand.network.model.OpencodeModelDto("zenmux/z-ai/glm-5.2", "zenmux", "GLM-5.2 (Pro)", false, "Standard GLM-5.2"),
            com.vinhcommand.network.model.OpencodeModelDto("zenmux/moonshotai/kimi-k3", "zenmux", "Kimi K3 (Pro)", false, "Full Kimi K3 instance"),
            // Kilo Gateway - Free models first
            com.vinhcommand.network.model.OpencodeModelDto("kilo/poolside/laguna-xs-2.1:free", "kilo", "Laguna XS 2.1 (Free)", true, "Poolside high-speed code model"),
            com.vinhcommand.network.model.OpencodeModelDto("kilo/poolside/laguna-s-2.1:free", "kilo", "Laguna S 2.1 (Free)", true, "Poolside standard code model"),
            com.vinhcommand.network.model.OpencodeModelDto("kilo/stepfun/step-3.7-flash:free", "kilo", "Step 3.7 Flash (Free)", true, "StepFun flash reasoning"),
            com.vinhcommand.network.model.OpencodeModelDto("kilo/thinkingmachines/inkling-small:free", "kilo", "Inkling Small (Free)", true, "ThinkingMachines lightweight assistant"),
            com.vinhcommand.network.model.OpencodeModelDto("kilo/liquid/lfm-2.5-2.6b:free", "kilo", "LFM 2.5 2.6B (Free)", true, "Liquid AI compact model"),
            com.vinhcommand.network.model.OpencodeModelDto("kilo/nex-agi/nex-n2.5-mini:free", "kilo", "NEX N2.5 Mini (Free)", true, "NEX AGI compact reasoning"),
            com.vinhcommand.network.model.OpencodeModelDto("kilo/nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free", "kilo", "Nemotron 3 Nano Reasoning (Free)", true, "NVIDIA 30B reasoning"),
            com.vinhcommand.network.model.OpencodeModelDto("kilo/nvidia/nemotron-3-super-120b-a12b:free", "kilo", "Nemotron 3 Super 120B (Free)", true, "NVIDIA 120B model"),
            com.vinhcommand.network.model.OpencodeModelDto("kilo/nvidia/nemotron-3-ultra-550b-a55b:free", "kilo", "Nemotron 3 Ultra 550B (Free)", true, "NVIDIA 550B model"),
            com.vinhcommand.network.model.OpencodeModelDto("kilo/nvidia/nemotron-3.5-lightning:free", "kilo", "Nemotron 3.5 Lightning (Free)", true, "NVIDIA lightning code model"),
            com.vinhcommand.network.model.OpencodeModelDto("kilo/qwen/qwen3.8-27b:free", "kilo", "Qwen 3.8 27B (Free)", true, "Alibaba Qwen 3.8 coding"),
            com.vinhcommand.network.model.OpencodeModelDto("kilo/z-ai/glm-5.2:free", "kilo", "GLM-5.2 (Free)", true, "GLM-5.2 via Kilo"),
            // OpenCode Zen - Free models first
            com.vinhcommand.network.model.OpencodeModelDto("opencode/ling-3.0-flash-fin-free", "opencode", "Ling 3.0 Flash Fin (Free)", true, "High precision logic"),
            com.vinhcommand.network.model.OpencodeModelDto("opencode/mimo-v2.5-free", "opencode", "Mimo v2.5 (Free)", true, "Xiaomi Mimo code model"),
            com.vinhcommand.network.model.OpencodeModelDto("opencode/muse-spark-1.2-contributor-free", "opencode", "Muse Spark 1.2 (Free)", true, "Contributor free model"),
            com.vinhcommand.network.model.OpencodeModelDto("opencode/muse-spark-1.3-contributor-free", "opencode", "Muse Spark 1.3 (Free)", true, "Next-gen contributor free"),
            com.vinhcommand.network.model.OpencodeModelDto("opencode/nemotron-3-ultra-free", "opencode", "Nemotron 3 Ultra (Free)", true, "NVIDIA ultra free"),
            com.vinhcommand.network.model.OpencodeModelDto("opencode/nemotron-3.5-lightning-free", "opencode", "Nemotron 3.5 Lightning (Free)", true, "NVIDIA lightning free")
        )
    )
    val opencodeModels = _opencodeModels.asStateFlow()

    private val _selectedOpencodeProvider = MutableStateFlow("zenmux")
    val selectedOpencodeProvider = _selectedOpencodeProvider.asStateFlow()

    private val _selectedOpencodeModel = MutableStateFlow("zenmux/z-ai/glm-4.6v-flash-free")
    val selectedOpencodeModel = _selectedOpencodeModel.asStateFlow()

    fun selectOpencodeProvider(providerId: String) {
        _selectedOpencodeProvider.value = providerId
        val modelsForProvider = _opencodeModels.value.filter { it.providerId == providerId }
        val freeFirst = modelsForProvider.filter { it.isFree }
        _selectedOpencodeModel.value = freeFirst.firstOrNull()?.id ?: modelsForProvider.firstOrNull()?.id ?: ""
    }

    fun selectOpencodeModel(modelId: String) {
        _selectedOpencodeModel.value = modelId
    }

    fun fetchOpencodeModels() {
        viewModelScope.launch {
            try {
                val res = api.getOpencodeModels()
                val data = res.body()?.data
                if (res.isSuccessful && data != null) {
                    if (data.providers.isNotEmpty()) _opencodeProviders.value = data.providers
                    if (data.models.isNotEmpty()) _opencodeModels.value = data.models
                }
            } catch (_: Exception) {}
        }
    }

    fun scanAiAgents() {
        viewModelScope.launch {
            _aiLoading.value = true
            try {
                fetchOpencodeModels()
                val res = api.scanAgents()
                if (res.isSuccessful) {
                    _message.value = "Scanned available desktop AI agents successfully!"
                    try { api.getPcState() } catch (_: Exception) {}
                } else {
                    _message.value = "PC Agent Scan returned code: ${res.code()}"
                }
            } catch (e: Exception) {
                _message.value = "Error scanning PC agents: ${e.message}"
            } finally {
                _aiLoading.value = false
            }
        }
    }

    fun runAiAutomate(provider: String, prompt: String, projectPath: String, currentFile: String?, selectedCode: String?, mode: String = "assisted", model: String? = null) {
        if (prompt.isBlank()) {
            _message.value = "Please enter task prompt"
            return
        }
        viewModelScope.launch {
            _aiLoading.value = true
            try {
                val req = mutableMapOf(
                    "provider" to provider,
                    "prompt" to prompt,
                    "projectPath" to projectPath,
                    "mode" to mode
                )
                if (currentFile != null) req["currentFile"] = currentFile
                if (selectedCode != null) req["selectedCode"] = selectedCode
                if (model != null && model.isNotBlank()) req["model"] = model
                val res = api.aiAutomate(req)
                val data = res.body()?.data
                if (res.isSuccessful && data != null) {
                    _aiResponse.value = data
                    _isAiOverlayOpen.value = true
                    _isAiOverlayMinimized.value = false
                    _message.value = "AI ($provider) đã phản hồi và cập nhật Task Tổng!"
                    connection.refreshPcState()
                    if (mode == "autonomous") {
                        applyAiPatch()
                    }
                } else {
                    _message.value = "AI response failed: ${res.code()}"
                }
            } catch (e: Exception) {
                _message.value = "Error contacting AI: ${e.message}"
            } finally {
                _aiLoading.value = false
            }
        }
    }

    fun applyAiPatch() {
        val current = _aiResponse.value ?: return
        viewModelScope.launch {
            _aiLoading.value = true
            try {
                val patchesMap = mapOf("applied" to "true")
                val res = api.applyAiPatch(patchesMap)
                if (res.isSuccessful) {
                    _message.value = "Bản vá đã được áp dụng vào dự án trên PC!"
                    connection.refreshPcState()
                    // Reload active file if open
                    _activeFilePath.value?.let { openFile(it) }
                } else {
                    _message.value = "Unable to apply AI patch"
                }
            } catch (e: Exception) {
                _message.value = "Error applying patch: ${e.message}"
            } finally {
                _aiLoading.value = false
            }
        }
    }

    fun rejectAiPatch() {
        _aiResponse.value = null
        _isAiOverlayOpen.value = false
        _isAiOverlayMinimized.value = false
        _message.value = "AI changes discarded."
    }

    fun addProjectFromDesktop(path: String, onDone: () -> Unit = {}) {
        if (_busy.value) return
        viewModelScope.launch {
            _busy.value = true
            try {
                val res = api.addProject(mapOf("path" to path.trim(), "accessMode" to "workspace-write"))
                if (res.isSuccessful && res.body()?.success == true) {
                    _message.value = "Project added successfully: ${path.split('\\', '/').lastOrNull() ?: path}"
                    onDone()
                } else {
                    _message.value = res.body()?.error?.message ?: "Unable to add project (${res.code()})"
                }
            } catch (e: Exception) {
                _message.value = e.message ?: "Connection error while adding project"
            } finally {
                _busy.value = false
            }
        }
    }

    // --- Floating Project IDE Window & Chat Bubble ---
    private val _isProjectOverlayOpen = MutableStateFlow(false)
    val isProjectOverlayOpen = _isProjectOverlayOpen.asStateFlow()

    private val _isProjectOverlayMinimized = MutableStateFlow(false)
    val isProjectOverlayMinimized = _isProjectOverlayMinimized.asStateFlow()

    private val _floatingProject = MutableStateFlow<Project?>(null)
    val floatingProject = _floatingProject.asStateFlow()

    fun openProjectOverlay(project: Project) {
        _floatingProject.value = project
        _isProjectOverlayOpen.value = true
        _isProjectOverlayMinimized.value = false
        browseFs(project.path)
        detectProjectRunners(project.path)
    }

    fun minimizeProjectOverlay() {
        _isProjectOverlayMinimized.value = true
    }

    fun restoreProjectOverlay() {
        _isProjectOverlayMinimized.value = false
    }

    fun closeProjectOverlay() {
        _isProjectOverlayOpen.value = false
        _isProjectOverlayMinimized.value = false
        closeActiveFile()
    }

    // --- GitHub Integration ---
    private val _githubUsername = MutableStateFlow("")
    val githubUsername = _githubUsername.asStateFlow()

    private val _isGithubLoggedIn = MutableStateFlow(false)
    val isGithubLoggedIn = _isGithubLoggedIn.asStateFlow()

    fun loginGithub(username: String, token: String) {
        viewModelScope.launch {
            try {
                val res = api.githubLogin(mapOf("username" to username, "token" to token))
                if (res.isSuccessful) {
                    _githubUsername.value = username
                    _isGithubLoggedIn.value = true
                    _message.value = "GitHub authenticated as $username"
                } else {
                    _message.value = "GitHub authentication failed"
                }
            } catch (e: Exception) {
                _message.value = "Login error: ${e.message}"
            }
        }
    }

    fun cloneGithubRepo(repoUrl: String, targetDir: String, onDone: () -> Unit = {}) {
        viewModelScope.launch {
            _busy.value = true
            try {
                val res = api.cloneRepo(mapOf("repoUrl" to repoUrl.trim(), "targetDir" to targetDir.trim()))
                if (res.isSuccessful) {
                    _message.value = "Cloned repository successfully!"
                    onDone()
                } else {
                    _message.value = "Failed to clone repository"
                }
            } catch (e: Exception) {
                _message.value = "Clone error: ${e.message}"
            } finally {
                _busy.value = false
            }
        }
    }

    // --- Smart Runner & Mobile APK Build ---
    private val _runnerState = MutableStateFlow<com.vinhcommand.network.model.RunnerDetectResponse?>(null)
    val runnerState = _runnerState.asStateFlow()

    private val _isBuildingApk = MutableStateFlow(false)
    val isBuildingApk = _isBuildingApk.asStateFlow()

    private val _apkDownloadUrl = MutableStateFlow<String?>(null)
    val apkDownloadUrl = _apkDownloadUrl.asStateFlow()

    private val _activeRunnerPid = MutableStateFlow<Int?>(null)
    val activeRunnerPid = _activeRunnerPid.asStateFlow()

    private val _activeWebUrl = MutableStateFlow<String?>(null)
    val activeWebUrl = _activeWebUrl.asStateFlow()

    fun detectProjectRunners(projectPath: String) {
        viewModelScope.launch {
            try {
                val res = api.detectRunners(projectPath)
                if (res.isSuccessful && res.body()?.success == true) {
                    _runnerState.value = res.body()?.data
                }
            } catch (_: Exception) {}
        }
    }

    fun startProjectRunner(command: String, cwd: String, port: Int? = null, previewUrl: String? = null, openCmd: Boolean = false) {
        viewModelScope.launch {
            try {
                val body = mutableMapOf("command" to command, "cwd" to cwd)
                if (port != null) body["port"] = port.toString()
                if (openCmd) body["openCmd"] = "true"
                val res = api.startRunner(body)
                if (res.isSuccessful && res.body()?.success == true) {
                    val data = res.body()?.data
                    _activeRunnerPid.value = data?.pid
                    _activeWebUrl.value = data?.previewUrl ?: previewUrl
                    _message.value = if (openCmd) "Đã mở cửa sổ CMD: $command" else "Đang chạy: $command"
                } else {
                    _message.value = "Không thể khởi chạy lệnh"
                }
            } catch (e: Exception) {
                _message.value = "Lỗi khởi chạy: ${e.message}"
            }
        }
    }

    fun stopActiveRunner() {
        val pid = _activeRunnerPid.value ?: return
        viewModelScope.launch {
            try {
                api.stopRunner(mapOf("pid" to pid))
                _activeRunnerPid.value = null
                _activeWebUrl.value = null
                _message.value = "Đã dừng tiến trình"
            } catch (_: Exception) {}
        }
    }

    fun buildApkForMobile(projectPath: String, onApkReady: (String, String) -> Unit = { _, _ -> }) {
        viewModelScope.launch {
            _isBuildingApk.value = true
            _message.value = "Đang tự động biên dịch APK trên PC..."
            try {
                val res = api.buildApk(mapOf("path" to projectPath))
                if (res.isSuccessful && res.body()?.success == true) {
                    val data = res.body()?.data
                    if (data?.success == true && data.downloadUrl != null) {
                        _apkDownloadUrl.value = data.downloadUrl
                        _message.value = "Đã tạo APK thành công: ${data.fileName}"
                        onApkReady(data.downloadUrl, data.fileName ?: "app-debug.apk")
                    } else {
                        _message.value = data?.message ?: "Không tìm thấy file APK sau khi build"
                    }
                } else {
                    _message.value = res.body()?.error?.message ?: "Lỗi build APK (${res.code()})"
                }
            } catch (e: Exception) {
                _message.value = "Lỗi kết nối build APK: ${e.message}"
            } finally {
                _isBuildingApk.value = false
            }
        }
    }

    fun disconnect() { viewModelScope.launch { connection.disconnect() } }
}
