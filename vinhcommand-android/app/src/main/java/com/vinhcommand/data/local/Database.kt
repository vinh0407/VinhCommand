package com.vinhcommand.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters

@Database(
    entities = [
        ComputerEntity::class,
        ProjectEntity::class,
        AgentEntity::class,
        TaskEntity::class,
        NotificationEntity::class,
        TerminalSessionEntity::class,
        FileNodeEntity::class,
        GitStatusEntity::class,
        ProcessEntity::class,
        ServerEntity::class,
        AuditLogEntity::class,
        ApprovalEntity::class,
        DeviceInfoEntity::class,
        SessionStateEntity::class,
        RecentComputerEntity::class,
        PromptTemplateEntity::class,
        PromptHistoryEntity::class,
        SettingsEntity::class
    ],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class VinhCommandDatabase : RoomDatabase() {

    abstract fun computerDao(): ComputerDao
    abstract fun projectDao(): ProjectDao
    abstract fun agentDao(): AgentDao
    abstract fun taskDao(): TaskDao
    abstract fun notificationDao(): NotificationDao
    abstract fun terminalSessionDao(): TerminalSessionDao
    abstract fun fileNodeDao(): FileNodeDao
    abstract fun gitStatusDao(): GitStatusDao
    abstract fun processDao(): ProcessDao
    abstract fun serverDao(): ServerDao
    abstract fun auditLogDao(): AuditLogDao
    abstract fun approvalDao(): ApprovalDao
    abstract fun deviceInfoDao(): DeviceInfoDao
    abstract fun sessionStateDao(): SessionStateDao
    abstract fun recentComputerDao(): RecentComputerDao
    abstract fun promptTemplateDao(): PromptTemplateDao
    abstract fun promptHistoryDao(): PromptHistoryDao
    abstract fun settingsDao(): SettingsDao

    companion object {
        @Volatile
        private var INSTANCE: VinhCommandDatabase? = null

        fun getInstance(context: Context): VinhCommandDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    VinhCommandDatabase::class.java,
                    "vinhcommand.db"
                )
                    .fallbackToDestructiveMigration()
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
