package com.vinhcommand.di

import com.vinhcommand.domain.usecase.agent.*
import com.vinhcommand.domain.usecase.computer.*
import com.vinhcommand.domain.usecase.connection.*
import com.vinhcommand.domain.usecase.file.*
import com.vinhcommand.domain.usecase.git.*
import com.vinhcommand.domain.usecase.notification.*
import com.vinhcommand.domain.usecase.process.*
import com.vinhcommand.domain.usecase.project.*
import com.vinhcommand.domain.usecase.security.*
import com.vinhcommand.domain.usecase.server.*
import com.vinhcommand.domain.usecase.task.*
import com.vinhcommand.domain.usecase.terminal.*
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import dagger.Module
import dagger.Provides
import kotlinx.coroutines.CoroutineScope
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object UseCaseModule {

    @Provides
    @Singleton
    fun provideGetComputersUseCase(repository: com.vinhcommand.domain.repository.ComputerRepository, scope: CoroutineScope) =
        GetComputersUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideGetComputerUseCase(repository: com.vinhcommand.domain.repository.ComputerRepository, scope: CoroutineScope) =
        GetComputerUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideSaveComputerUseCase(repository: com.vinhcommand.domain.repository.ComputerRepository, scope: CoroutineScope) =
        SaveComputerUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideDeleteComputerUseCase(repository: com.vinhcommand.domain.repository.ComputerRepository, scope: CoroutineScope) =
        DeleteComputerUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideObserveComputersUseCase(repository: com.vinhcommand.domain.repository.ComputerRepository) =
        ObserveComputersUseCase(repository)

    @Provides
    @Singleton
    fun provideGetProjectsUseCase(repository: com.vinhcommand.domain.repository.ProjectRepository, scope: CoroutineScope) =
        GetProjectsUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideGetProjectUseCase(repository: com.vinhcommand.domain.repository.ProjectRepository, scope: CoroutineScope) =
        GetProjectUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideGetProjectDetailUseCase(repository: com.vinhcommand.domain.repository.ProjectRepository, scope: CoroutineScope) =
        GetProjectDetailUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideRefreshProjectsUseCase(repository: com.vinhcommand.domain.repository.ProjectRepository, scope: CoroutineScope) =
        RefreshProjectsUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideObserveProjectsUseCase(repository: com.vinhcommand.domain.repository.ProjectRepository) =
        ObserveProjectsUseCase(repository)

    @Provides
    @Singleton
    fun provideGetAgentsUseCase(repository: com.vinhcommand.domain.repository.AgentRepository, scope: CoroutineScope) =
        GetAgentsUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideGetAgentUseCase(repository: com.vinhcommand.domain.repository.AgentRepository, scope: CoroutineScope) =
        GetAgentUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideGetAgentDetailUseCase(repository: com.vinhcommand.domain.repository.AgentRepository, scope: CoroutineScope) =
        GetAgentDetailUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideLaunchAgentUseCase(repository: com.vinhcommand.domain.repository.AgentRepository, scope: CoroutineScope) =
        LaunchAgentUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideStopAgentUseCase(repository: com.vinhcommand.domain.repository.AgentRepository, scope: CoroutineScope) =
        StopAgentUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideSendAgentPromptUseCase(repository: com.vinhcommand.domain.repository.AgentRepository, scope: CoroutineScope) =
        SendAgentPromptUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideObserveAgentsUseCase(repository: com.vinhcommand.domain.repository.AgentRepository) =
        ObserveAgentsUseCase(repository)

    @Provides
    @Singleton
    fun provideGetTasksUseCase(repository: com.vinhcommand.domain.repository.TaskRepository, scope: CoroutineScope) =
        GetTasksUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideGetTaskUseCase(repository: com.vinhcommand.domain.repository.TaskRepository, scope: CoroutineScope) =
        GetTaskUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideCreateTaskUseCase(repository: com.vinhcommand.domain.repository.TaskRepository, scope: CoroutineScope) =
        CreateTaskUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideControlTaskUseCase(repository: com.vinhcommand.domain.repository.TaskRepository, scope: CoroutineScope) =
        ControlTaskUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideGetTaskOutputUseCase(repository: com.vinhcommand.domain.repository.TaskRepository, scope: CoroutineScope) =
        GetTaskOutputUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideGetTaskTimelineUseCase(repository: com.vinhcommand.domain.repository.TaskRepository, scope: CoroutineScope) =
        GetTaskTimelineUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideGetTaskDiffUseCase(repository: com.vinhcommand.domain.repository.TaskRepository, scope: CoroutineScope) =
        GetTaskDiffUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideObserveTasksUseCase(repository: com.vinhcommand.domain.repository.TaskRepository) =
        ObserveTasksUseCase(repository)

    @Provides
    @Singleton
    fun provideObserveTaskOutputUseCase(repository: com.vinhcommand.domain.repository.TaskRepository) =
        ObserveTaskOutputUseCase(repository)

    @Provides
    @Singleton
    fun provideCreateTerminalSessionUseCase(repository: com.vinhcommand.domain.repository.TerminalRepository, scope: CoroutineScope) =
        CreateTerminalSessionUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideSendTerminalCommandUseCase(repository: com.vinhcommand.domain.repository.TerminalRepository, scope: CoroutineScope) =
        SendTerminalCommandUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideResizeTerminalSessionUseCase(repository: com.vinhcommand.domain.repository.TerminalRepository, scope: CoroutineScope) =
        ResizeTerminalSessionUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideCloseTerminalSessionUseCase(repository: com.vinhcommand.domain.repository.TerminalRepository, scope: CoroutineScope) =
        CloseTerminalSessionUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideObserveTerminalSessionUseCase(repository: com.vinhcommand.domain.repository.TerminalRepository) =
        ObserveTerminalSessionUseCase(repository)

    @Provides
    @Singleton
    fun provideObserveTerminalOutputUseCase(repository: com.vinhcommand.domain.repository.TerminalRepository) =
        ObserveTerminalOutputUseCase(repository)

    @Provides
    @Singleton
    fun provideListFilesUseCase(repository: com.vinhcommand.domain.repository.FileRepository, scope: CoroutineScope) =
        ListFilesUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideReadFileUseCase(repository: com.vinhcommand.domain.repository.FileRepository, scope: CoroutineScope) =
        ReadFileUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideWriteFileUseCase(repository: com.vinhcommand.domain.repository.FileRepository, scope: CoroutineScope) =
        WriteFileUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideCreateFileUseCase(repository: com.vinhcommand.domain.repository.FileRepository, scope: CoroutineScope) =
        CreateFileUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideDeleteFileUseCase(repository: com.vinhcommand.domain.repository.FileRepository, scope: CoroutineScope) =
        DeleteFileUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideRenameFileUseCase(repository: com.vinhcommand.domain.repository.FileRepository, scope: CoroutineScope) =
        RenameFileUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideObserveFileTreeUseCase(repository: com.vinhcommand.domain.repository.FileRepository) =
        ObserveFileTreeUseCase(repository)

    @Provides
    @Singleton
    fun provideGetGitStatusUseCase(repository: com.vinhcommand.domain.repository.GitRepository, scope: CoroutineScope) =
        GetGitStatusUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideGetGitDiffUseCase(repository: com.vinhcommand.domain.repository.GitRepository, scope: CoroutineScope) =
        GetGitDiffUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideStageFileUseCase(repository: com.vinhcommand.domain.repository.GitRepository, scope: CoroutineScope) =
        StageFileUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideUnstageFileUseCase(repository: com.vinhcommand.domain.repository.GitRepository, scope: CoroutineScope) =
        UnstageFileUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideCommitChangesUseCase(repository: com.vinhcommand.domain.repository.GitRepository, scope: CoroutineScope) =
        CommitChangesUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideGetBranchesUseCase(repository: com.vinhcommand.domain.repository.GitRepository, scope: CoroutineScope) =
        GetBranchesUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideCheckoutBranchUseCase(repository: com.vinhcommand.domain.repository.GitRepository, scope: CoroutineScope) =
        CheckoutBranchUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideObserveGitStatusUseCase(repository: com.vinhcommand.domain.repository.GitRepository) =
        ObserveGitStatusUseCase(repository)

    @Provides
    @Singleton
    fun provideGetProcessesUseCase(repository: com.vinhcommand.domain.repository.ProcessRepository, scope: CoroutineScope) =
        GetProcessesUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideKillProcessUseCase(repository: com.vinhcommand.domain.repository.ProcessRepository, scope: CoroutineScope) =
        KillProcessUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideObserveProcessesUseCase(repository: com.vinhcommand.domain.repository.ProcessRepository) =
        ObserveProcessesUseCase(repository)

    @Provides
    @Singleton
    fun provideGetServersUseCase(repository: com.vinhcommand.domain.repository.ServerRepository, scope: CoroutineScope) =
        GetServersUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideStartServerUseCase(repository: com.vinhcommand.domain.repository.ServerRepository, scope: CoroutineScope) =
        StartServerUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideStopServerUseCase(repository: com.vinhcommand.domain.repository.ServerRepository, scope: CoroutineScope) =
        StopServerUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideObserveServersUseCase(repository: com.vinhcommand.domain.repository.ServerRepository) =
        ObserveServersUseCase(repository)

    @Provides
    @Singleton
    fun provideGetSessionStateUseCase(repository: com.vinhcommand.domain.repository.SecurityRepository, scope: CoroutineScope) =
        GetSessionStateUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideGetAuditLogsUseCase(repository: com.vinhcommand.domain.repository.SecurityRepository, scope: CoroutineScope) =
        GetAuditLogsUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideGetPendingApprovalsUseCase(repository: com.vinhcommand.domain.repository.SecurityRepository, scope: CoroutineScope) =
        GetPendingApprovalsUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideApproveCommandUseCase(repository: com.vinhcommand.domain.repository.SecurityRepository, scope: CoroutineScope) =
        ApproveCommandUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideGetDeviceTrustUseCase(repository: com.vinhcommand.domain.repository.SecurityRepository, scope: CoroutineScope) =
        GetDeviceTrustUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideSetDeviceTrustUseCase(repository: com.vinhcommand.domain.repository.SecurityRepository, scope: CoroutineScope) =
        SetDeviceTrustUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideTriggerKillSwitchUseCase(repository: com.vinhcommand.domain.repository.SecurityRepository, scope: CoroutineScope) =
        TriggerKillSwitchUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideObserveSessionStateUseCase(repository: com.vinhcommand.domain.repository.SecurityRepository) =
        ObserveSessionStateUseCase(repository)

    @Provides
    @Singleton
    fun provideObserveApprovalsUseCase(repository: com.vinhcommand.domain.repository.SecurityRepository) =
        ObserveApprovalsUseCase(repository)

    @Provides
    @Singleton
    fun provideGetNotificationsUseCase(repository: com.vinhcommand.domain.repository.NotificationRepository, scope: CoroutineScope) =
        GetNotificationsUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideMarkNotificationAsReadUseCase(repository: com.vinhcommand.domain.repository.NotificationRepository, scope: CoroutineScope) =
        MarkNotificationAsReadUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideMarkAllNotificationsAsReadUseCase(repository: com.vinhcommand.domain.repository.NotificationRepository, scope: CoroutineScope) =
        MarkAllNotificationsAsReadUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideClearNotificationsUseCase(repository: com.vinhcommand.domain.repository.NotificationRepository, scope: CoroutineScope) =
        ClearNotificationsUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideObserveNotificationsUseCase(repository: com.vinhcommand.domain.repository.NotificationRepository) =
        ObserveNotificationsUseCase(repository)

    @Provides
    @Singleton
    fun provideObserveUnreadCountUseCase(repository: com.vinhcommand.domain.repository.NotificationRepository) =
        ObserveUnreadCountUseCase(repository)

    @Provides
    @Singleton
    fun provideConnectToPcUseCase(repository: com.vinhcommand.domain.repository.ConnectionRepository, scope: CoroutineScope) =
        ConnectToPcUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideDisconnectFromPcUseCase(repository: com.vinhcommand.domain.repository.ConnectionRepository, scope: CoroutineScope) =
        DisconnectFromPcUseCase(repository, scope)

    @Provides
    @Singleton
    fun providePairWithPcUseCase(repository: com.vinhcommand.domain.repository.ConnectionRepository, scope: CoroutineScope) =
        PairWithPcUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideAuthenticateWithPcUseCase(repository: com.vinhcommand.domain.repository.ConnectionRepository, scope: CoroutineScope) =
        AuthenticateWithPcUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideTrustDeviceUseCase(repository: com.vinhcommand.domain.repository.ConnectionRepository, scope: CoroutineScope) =
        TrustDeviceUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideRefreshSessionUseCase(repository: com.vinhcommand.domain.repository.ConnectionRepository, scope: CoroutineScope) =
        RefreshSessionUseCase(repository, scope)

    @Provides
    @Singleton
    fun provideObserveConnectionStateUseCase(repository: com.vinhcommand.domain.repository.ConnectionRepository) =
        ObserveConnectionStateUseCase(repository)

    @Provides
    @Singleton
    fun provideObservePcStateUseCase(repository: com.vinhcommand.domain.repository.ConnectionRepository) =
        ObservePcStateUseCase(repository)
}
