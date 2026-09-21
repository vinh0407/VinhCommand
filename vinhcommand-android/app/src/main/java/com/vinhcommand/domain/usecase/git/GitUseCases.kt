package com.vinhcommand.domain.usecase.git

import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.GitRepository
import com.vinhcommand.domain.usecase.BaseUseCase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*

class GetGitStatusUseCase(
    private val gitRepository: GitRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<GitStatusOverview>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<GitStatusOverview> {
        return gitRepository.getStatus(params)
    }
}

class GetGitDiffUseCase(
    private val gitRepository: GitRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Pair<String, String>, Result<GitDiff>>(coroutineScope) {

    override suspend operator fun invoke(params: Pair<String, String>): Result<GitDiff> {
        return gitRepository.getDiff(params.first, params.second)
    }
}

class StageFileUseCase(
    private val gitRepository: GitRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Pair<String, String>, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: Pair<String, String>): Result<Unit> {
        return gitRepository.stageFile(params.first, params.second)
    }
}

class UnstageFileUseCase(
    private val gitRepository: GitRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Pair<String, String>, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: Pair<String, String>): Result<Unit> {
        return gitRepository.unstageFile(params.first, params.second)
    }
}

class CommitChangesUseCase(
    private val gitRepository: GitRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Pair<String, String>, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: Pair<String, String>): Result<Unit> {
        return gitRepository.commit(params.first, params.second)
    }
}

class GetBranchesUseCase(
    private val gitRepository: GitRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<List<String>>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<List<String>> {
        return gitRepository.getBranches(params)
    }
}

class CheckoutBranchUseCase(
    private val gitRepository: GitRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Pair<String, String>, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: Pair<String, String>): Result<Unit> {
        return gitRepository.checkoutBranch(params.first, params.second)
    }
}

class ObserveGitStatusUseCase(
    private val gitRepository: GitRepository
) {
    operator fun invoke(projectId: String): StateFlow<GitStatusOverview> {
        return gitRepository.gitStatusFlow
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = GitStatusOverview("", 0, 0, emptyList(), emptyList())
            ) 
    }
}

