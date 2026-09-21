package com.vinhcommand.data.local

import androidx.room.TypeConverter
import com.vinhcommand.domain.model.*
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class Converters {

    private val json = Json { ignoreUnknownKeys = true }

    @TypeConverter
    fun fromHardwareStats(jsonStr: String?): HardwareStats? {
        return jsonStr?.let { json.decodeFromString<HardwareStats>(it) }
    }

    @TypeConverter
    fun toHardwareStats(stats: HardwareStats?): String? {
        return stats?.let { json.encodeToString(it) }
    }

    @TypeConverter
    fun fromStatsSummary(jsonStr: String?): StatsSummary? {
        return jsonStr?.let { json.decodeFromString<StatsSummary>(it) }
    }

    @TypeConverter
    fun toStatsSummary(summary: StatsSummary?): String? {
        return summary?.let { json.encodeToString(it) }
    }

    @TypeConverter
    fun fromListString(jsonStr: String): List<String> {
        return json.decodeFromString(jsonStr)
    }

    @TypeConverter
    fun toListString(list: List<String>): String {
        return json.encodeToString(list)
    }

    @TypeConverter
    fun fromAgentCapabilities(jsonStr: String): AgentCapabilities {
        return json.decodeFromString(jsonStr)
    }

    @TypeConverter
    fun toAgentCapabilities(caps: AgentCapabilities): String {
        return json.encodeToString(caps)
    }

    @TypeConverter
    fun fromTaskTimeline(jsonStr: String): List<TaskTimelineEvent> {
        return json.decodeFromString(jsonStr)
    }

    @TypeConverter
    fun toTaskTimeline(timeline: List<TaskTimelineEvent>): String {
        return json.encodeToString(timeline)
    }

    @TypeConverter
    fun fromTestResults(jsonStr: String?): TestResults? {
        return jsonStr?.let { json.decodeFromString<TestResults>(it) }
    }

    @TypeConverter
    fun toTestResults(results: TestResults?): String? {
        return results?.let { json.encodeToString(it) }
    }

    @TypeConverter
    fun fromGitDiff(jsonStr: String?): GitDiff? {
        return jsonStr?.let { json.decodeFromString<GitDiff>(it) }
    }

    @TypeConverter
    fun toGitDiff(diff: GitDiff?): String? {
        return diff?.let { json.encodeToString(it) }
    }

    @TypeConverter
    fun fromFileNodes(jsonStr: String?): List<FileNode>? {
        return jsonStr?.let { json.decodeFromString(it) }
    }

    @TypeConverter
    fun toFileNodes(nodes: List<FileNode>?): String? {
        return nodes?.let { json.encodeToString(it) }
    }

    @TypeConverter
    fun fromGitFileStatus(jsonStr: String): List<GitFileStatus> {
        return json.decodeFromString(jsonStr)
    }

    @TypeConverter
    fun toGitFileStatus(files: List<GitFileStatus>): String {
        return json.encodeToString(files)
    }

    @TypeConverter
    fun fromGitCommits(jsonStr: String): List<GitCommit> {
        return json.decodeFromString(jsonStr)
    }

    @TypeConverter
    fun toGitCommits(commits: List<GitCommit>): String {
        return json.encodeToString(commits)
    }

    @TypeConverter
    fun fromMetadata(jsonStr: String): Map<String, String> {
        return json.decodeFromString(jsonStr)
    }

    @TypeConverter
    fun toMetadata(map: Map<String, String>): String {
        return json.encodeToString(map)
    }
}
