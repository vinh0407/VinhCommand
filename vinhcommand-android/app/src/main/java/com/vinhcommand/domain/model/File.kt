package com.vinhcommand.domain.model

import androidx.annotation.Keep
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Keep
@Serializable
data class FileNode(
    val id: String,
    val name: String,
    val path: String,
    val isDirectory: Boolean,
    val sizeBytes: Long? = null,
    val modifiedAt: String? = null,
    val children: List<FileNode>? = null
)

@Keep
@Serializable
data class FileContent(
    val path: String,
    val content: String,
    val encoding: String = "utf-8",
    val sizeBytes: Long,
    val modifiedAt: String
)

@Keep
@Serializable
data class FileOperationRequest(
    val operation: FileOperation,
    val path: String,
    val content: String? = null,
    val newPath: String? = null
)

@Keep
@Serializable
enum class FileOperation {
    @SerialName("read") READ,
    @SerialName("write") WRITE,
    @SerialName("create") CREATE,
    @SerialName("delete") DELETE,
    @SerialName("rename") RENAME,
    @SerialName("list") LIST
}

@Keep
@Serializable
data class FileOperationResponse(
    val success: Boolean,
    val path: String,
    val content: String? = null,
    val error: String? = null
)
