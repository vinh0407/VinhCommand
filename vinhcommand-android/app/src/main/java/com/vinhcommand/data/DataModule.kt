package com.vinhcommand.data

import androidx.room.Room
import com.vinhcommand.data.local.*
import com.vinhcommand.data.repository.*
import com.vinhcommand.domain.repository.*
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import dagger.Module
import dagger.Provides
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DataModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: android.content.Context): VinhCommandDatabase {
        return VinhCommandDatabase.getInstance(context)
    }

    @Provides
    @Singleton
    fun provideComputerDao(database: VinhCommandDatabase): ComputerDao = database.computerDao()

    @Provides
    @Singleton
    fun provideProjectDao(database: VinhCommandDatabase): ProjectDao = database.projectDao()

    @Provides
    @Singleton
    fun provideAgentDao(database: VinhCommandDatabase): AgentDao = database.agentDao()

    @Provides
    @Singleton
    fun provideTaskDao(database: VinhCommandDatabase): TaskDao = database.taskDao()

    @Provides
    @Singleton
    fun provideNotificationDao(database: VinhCommandDatabase): NotificationDao = database.notificationDao()

    @Provides
    @Singleton
    fun provideTerminalSessionDao(database: VinhCommandDatabase): TerminalSessionDao = database.terminalSessionDao()

    @Provides
    @Singleton
    fun provideFileNodeDao(database: VinhCommandDatabase): FileNodeDao = database.fileNodeDao()

    @Provides
    @Singleton
    fun provideGitStatusDao(database: VinhCommandDatabase): GitStatusDao = database.gitStatusDao()

    @Provides
    @Singleton
    fun provideProcessDao(database: VinhCommandDatabase): ProcessDao = database.processDao()

    @Provides
    @Singleton
    fun provideServerDao(database: VinhCommandDatabase): ServerDao = database.serverDao()

    @Provides
    @Singleton
    fun provideAuditLogDao(database: VinhCommandDatabase): AuditLogDao = database.auditLogDao()

    @Provides
    @Singleton
    fun provideApprovalDao(database: VinhCommandDatabase): ApprovalDao = database.approvalDao()

    @Provides
    @Singleton
    fun provideDeviceInfoDao(database: VinhCommandDatabase): DeviceInfoDao = database.deviceInfoDao()

    @Provides
    @Singleton
    fun provideSessionStateDao(database: VinhCommandDatabase): SessionStateDao = database.sessionStateDao()

    @Provides
    @Singleton
    fun provideRecentComputerDao(database: VinhCommandDatabase): RecentComputerDao = database.recentComputerDao()

    @Provides
    @Singleton
    fun providePromptTemplateDao(database: VinhCommandDatabase): PromptTemplateDao = database.promptTemplateDao()

    @Provides
    @Singleton
    fun providePromptHistoryDao(database: VinhCommandDatabase): PromptHistoryDao = database.promptHistoryDao()

    @Provides
    @Singleton
    fun provideSettingsDao(database: VinhCommandDatabase): SettingsDao = database.settingsDao()

    @Provides
    @Singleton
    fun provideComputerRepository(impl: ComputerRepositoryImpl): ComputerRepository = impl

    @Provides
    @Singleton
    fun provideProjectRepository(impl: ProjectRepositoryImpl): ProjectRepository = impl

    @Provides
    @Singleton
    fun provideAgentRepository(impl: AgentRepositoryImpl): AgentRepository = impl

    @Provides
    @Singleton
    fun provideTaskRepository(impl: TaskRepositoryImpl): TaskRepository = impl

    @Provides
    @Singleton
    fun provideTerminalRepository(impl: TerminalRepositoryImpl): TerminalRepository = impl

    @Provides
    @Singleton
    fun provideFileRepository(impl: FileRepositoryImpl): FileRepository = impl

    @Provides
    @Singleton
    fun provideGitRepository(impl: GitRepositoryImpl): GitRepository = impl

    @Provides
    @Singleton
    fun provideProcessRepository(impl: ProcessRepositoryImpl): ProcessRepository = impl

    @Provides
    @Singleton
    fun provideServerRepository(impl: ServerRepositoryImpl): ServerRepository = impl

    @Provides
    @Singleton
    fun provideSecurityRepository(impl: SecurityRepositoryImpl): SecurityRepository = impl

    @Provides
    @Singleton
    fun provideNotificationRepository(impl: NotificationRepositoryImpl): NotificationRepository = impl

    @Provides
    @Singleton
    fun provideConnectionRepository(impl: ConnectionRepositoryImpl): ConnectionRepository = impl

    @Provides
    @Singleton
    fun provideCacheRepository(impl: CacheRepositoryImpl): CacheRepository = impl
}
