package com.vinhcommand.security

import android.content.Context
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import dagger.Module
import dagger.Provides
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object SecurityModule {

    @Provides
    @Singleton
    fun provideSecurityManager(
        @ApplicationContext context: Context,
        @IoDispatcher dispatcher: CoroutineDispatcher
    ): SecurityManager {
        return SecurityManager(context, dispatcher)
    }

    @Provides
    @Singleton
    fun provideAppLockManager(
        application: android.app.Application,
        securityManager: SecurityManager,
        @IoDispatcher dispatcher: CoroutineDispatcher
    ): AppLockManager {
        return AppLockManager(application, securityManager, dispatcher)
    }
}
