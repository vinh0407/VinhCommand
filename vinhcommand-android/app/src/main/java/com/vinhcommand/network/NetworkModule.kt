package com.vinhcommand.network

import com.google.common.util.concurrent.ListenableFuture
import com.vinhcommand.network.api.VinhCommandApi
import com.vinhcommand.network.model.ApiResponse
import com.vinhcommand.network.websocket.VinhCommandWebSocket
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import dagger.Module
import dagger.Provides
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import javax.inject.Singleton
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import io.reactivex.rxjava3.core.Observable

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @ServerUrl
    fun provideServerUrl(): String {
        return "http://127.0.0.1:8444/"
    }

    @Provides
    @Singleton
    fun provideMoshi(): Moshi {
        return Moshi.Builder()
            .add(KotlinJsonAdapterFactory())
            .build()
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(moshi: Moshi, session: CompanionSession): OkHttpClient {
        val loggingInterceptor = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.NONE
        }

        return OkHttpClient.Builder()
            .connectTimeout(10, java.util.concurrent.TimeUnit.SECONDS)
            .readTimeout(15, java.util.concurrent.TimeUnit.SECONDS)
            .followRedirects(false)
            .followSslRedirects(false)
            .addInterceptor(loggingInterceptor)
            .addInterceptor { chain ->
                val original = chain.request()
                val endpoint = session.endpoint
                val url = original.url.newBuilder().scheme(endpoint.scheme).host(endpoint.host).port(endpoint.port).build()
                val builder = original.newBuilder().url(url)
                    .addHeader("Accept", "application/json")
                    .addHeader("Content-Type", "application/json")
                session.token?.let { builder.header("Authorization", "Bearer $it") }
                chain.proceed(builder.build())
            }
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient, moshi: Moshi, @ServerUrl baseUrl: String): Retrofit {
        return Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(okHttpClient)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
    }

    @Provides
    @Singleton
    fun provideVinhCommandApi(retrofit: Retrofit): VinhCommandApi {
        return retrofit.create(VinhCommandApi::class.java)
    }

    @Provides
    @Singleton
    fun provideCoroutinesScope(): CoroutineScope {
        return CoroutineScope(SupervisorJob() + Dispatchers.Main)
    }

    @Provides
    @Singleton
    fun provideMainDispatcher(): CoroutineDispatcher = Dispatchers.Main

    @Provides
    @Singleton
    fun provideIoDispatcher(): CoroutineDispatcher = Dispatchers.IO

    @Provides
    @Singleton
    fun provideDefaultDispatcher(): CoroutineDispatcher = Dispatchers.Default
}

// Qualifier for server URL
@javax.inject.Qualifier
@Retention(AnnotationRetention.RUNTIME)
annotation class ServerUrl

