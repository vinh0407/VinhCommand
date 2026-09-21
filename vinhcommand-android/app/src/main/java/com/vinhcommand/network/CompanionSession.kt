package com.vinhcommand.network

import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrl
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CompanionSession @Inject constructor() {
    @Volatile var endpoint: HttpUrl = "http://127.0.0.1:8444/".toHttpUrl()
        private set
    @Volatile var token: String? = null
    fun configure(value: String) {
        val url = value.trim().toHttpUrl()
        require(url.username.isEmpty() && url.password.isEmpty() && url.encodedPath == "/" && url.query == null && url.fragment == null) {
            "Enter only the desktop address and port, without credentials or a path"
        }
        token = null
        endpoint = url
    }
}
