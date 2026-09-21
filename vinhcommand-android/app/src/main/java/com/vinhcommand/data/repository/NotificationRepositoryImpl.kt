package com.vinhcommand.data.repository

import com.vinhcommand.data.local.*
import com.vinhcommand.data.mapper.NotificationMapper
import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.NotificationRepository
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NotificationRepositoryImpl @Inject constructor(
    private val notificationDao: NotificationDao
) : NotificationRepository {

    private val notificationsChannel = Channel<List<NotificationItem>>()
    private val unreadCountChannel = Channel<Int>()

    override suspend fun getNotifications(): Result<List<NotificationItem>> {
        return try {
            val entities = notificationDao.getAll().first()
            Result.success(NotificationMapper.toDomainList(entities))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun markAsRead(id: String): Result<Unit> {
        return try {
            notificationDao.markAsRead(id)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun markAllAsRead(): Result<Unit> {
        return try {
            notificationDao.markAllAsRead()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun clearNotifications(): Result<Unit> {
        return try {
            notificationDao.clearAll()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override val notificationsFlow: Flow<List<NotificationItem>>
        get() = notificationsChannel.receiveAsFlow()

    override val unreadCountFlow: Flow<Int>
        get() = unreadCountChannel.receiveAsFlow()

    fun onNotificationsChanged(notifications: List<NotificationItem>) {
        notificationsChannel.trySend(notifications)
        unreadCountChannel.trySend(notifications.count { !it.read })
    }
}
