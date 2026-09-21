package com.vinhcommand.network

import org.junit.Assert.*
import org.junit.Test

class CompanionSessionTest {
    @Test fun changingServerRevokesToken() {
        val session = CompanionSession()
        session.configure("http://192.168.1.20:8444")
        session.token = "previous-session"
        session.configure("http://192.168.1.21:8444/")
        assertNull(session.token)
        assertEquals("192.168.1.21", session.endpoint.host)
        assertEquals(8444, session.endpoint.port)
    }
    @Test fun rejectsCredentialsInServerAddress() {
        assertThrows(IllegalArgumentException::class.java) {
            CompanionSession().configure("http://user:password@192.168.1.20:8444/")
        }
    }
}
