package com.vinhcommand.domain.usecase.project

import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.ProjectRepository
import com.vinhcommand.domain.usecase.BaseUseCase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*

class GetProjectsUseCase(
    private val projectRepository: ProjectRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<List<Project>>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<List<Project>> {
        return projectRepository.getProjects()
    }
}

class GetProjectUseCase(
    private val projectRepository: ProjectRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<Project>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<Project> {
        return projectRepository.getProject(params)
    }
}

class GetProjectDetailUseCase(
    private val projectRepository: ProjectRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<ProjectDetail>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<ProjectDetail> {
        return projectRepository.getProjectDetail(params)
    }
}

class RefreshProjectsUseCase(
    private val projectRepository: ProjectRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<List<Project>>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<List<Project>> {
        return projectRepository.refreshProjects()
    }
}

class ObserveProjectsUseCase(
    private val projectRepository: ProjectRepository
) {
    operator fun invoke(): StateFlow<List<Project>> {
        return projectRepository.projectsFlow
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = emptyList()
            )
    }
}

