package com.vinhcommand.network.websocket

import com.vinhcommand.domain.model.ConnectionState
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import retrofit2.Retrofit

interface VinhCommandWebSocket {
    fun observeEvents(): Channel<WsEvent>
    fun send(event: WsOutgoingEvent)
    fun close()
}

class WebSocketConnectionManager(
    private val retrofit: Retrofit,
    private val baseUrl: String,
    private val sessionToken: String
) {
    private val _connectionState = MutableStateFlow<ConnectionState>(ConnectionState.DISCONNECTED)
    val connectionState = _connectionState.asStateFlow()
    
    val eventsChannel = Channel<WsEvent>()

    fun connect() {
        _connectionState.value = ConnectionState.CONNECTING
    }

    fun disconnect() {
        _connectionState.value = ConnectionState.DISCONNECTED
    }

    fun send(event: WsOutgoingEvent) {
        // Mock send
    }

    fun subscribe(events: List<String>) {
    }

    fun unsubscribe(events: List<String>) {
    }
}
