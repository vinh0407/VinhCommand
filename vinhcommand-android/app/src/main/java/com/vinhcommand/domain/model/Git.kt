package com.vinhcommand.domain.model

import androidx.annotation.Keep
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Keep
@Serializable
data class GitStatusOverview(
    val branch: String,
    val ahead: Int,
    val behind: Int,
    val files: List<GitFileStatus>,
    val recentCommits: List<GitCommit>
)

@Keep
@Serializable
data class GitFileStatus(
    val path: String,
    val status: GitFileState,
    val staged: Boolean,
    val insertions: Int,
    val deletions: Int
)

@Keep
@Serializable
enum class GitFileState {
    @SerialName("modified") MODIFIED,
    @SerialName("added") ADDED,
    @SerialName("deleted") DELETED,
    @SerialName("untracked") UNTRACKED
}

@Keep
@Serializable
data class GitCommit(
    val hash: String,
    val message: String,
    val author: String,
    val date: String
)

@Keep
@Serializable
data class GitDiff(
    val filePath: String,
    val oldContent: String?,
    val newContent: String?,
    val hunks: List<GitDiffHunk>
)

@Keep
@Serializable
data class GitDiffHunk(
    val oldStart: Int,
    val oldLines: Int,
    val newStart: Int,
    val newLines: Int,
    val lines: List<GitDiffLine>
)

@Keep
@Serializable
data class GitDiffLine(
    val type: DiffLineType,
    val content: String,
    val oldLineNumber: Int?,
    val newLineNumber: Int?
)

@Keep
@Serializable
enum class DiffLineType {
    @SerialName("context") CONTEXT,
    @SerialName("added") ADDED,
    @SerialName("removed") REMOVED
}
