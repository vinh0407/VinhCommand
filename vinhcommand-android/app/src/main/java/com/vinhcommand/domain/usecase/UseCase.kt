package com.vinhcommand.domain.usecase

import kotlinx.coroutines.CoroutineScope

interface UseCase<in Params, out Result> {
    suspend operator fun invoke(params: Params): Result
}

abstract class BaseUseCase<Params, Result>(
    protected val coroutineScope: CoroutineScope
) : UseCase<Params, Result>
