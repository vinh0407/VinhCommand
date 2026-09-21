package com.vinhcommand.domain.usecase.notification

import com.vinhcommand.domain.model.NotificationItem
import com.vinhcommand.domain.repository.NotificationRepository
import com.vinhcommand.domain.usecase.BaseUseCase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*

class GetNotificationsUseCase(
    private val notificationRepository: NotificationRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<List<NotificationItem>>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<List<NotificationItem>> {
        return notificationRepository.getNotifications()
    }
}

class MarkNotificationAsReadUseCase(
    private val notificationRepository: NotificationRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<Unit> {
        return notificationRepository.markAsRead(params)
    }
}

class MarkAllNotificationsAsReadUseCase(
    private val notificationRepository: NotificationRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<Unit> {
        return notificationRepository.markAllAsRead()
    }
}

class ClearNotificationsUseCase(
    private val notificationRepository: NotificationRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<Unit> {
        return notificationRepository.clearNotifications()
    }
}

class ObserveNotificationsUseCase(
    private val notificationRepository: NotificationRepository
) {
    operator fun invoke(): StateFlow<List<NotificationItem>> {
        return notificationRepository.notificationsFlow
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = emptyList()
            )
    }
}

class ObserveUnreadCountUseCase(
    private val notificationRepository: NotificationRepository
) {
    operator fun invoke(): StateFlow<Int> {
        return notificationRepository.unreadCountFlow
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = 0
            ) 
    }
}

