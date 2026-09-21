package com.vinhcommand.presentation.common

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Provider

abstract class BaseViewModel : ViewModel() {

    protected val coroutineScope: CoroutineScope = viewModelScope

    protected fun launch(block: suspend CoroutineScope.() -> Unit) = coroutineScope.launch(block = block)

    private val _uiState = kotlinx.coroutines.flow.MutableStateFlow<UiState>(UiState.Idle)
    val uiState: kotlinx.coroutines.flow.StateFlow<UiState> = _uiState

    protected fun setState(state: UiState) {
        _uiState.value = state
    }

    sealed interface UiState {
        object Idle : UiState
        data class Loading(val message: String = "Loading...") : UiState
        data class Success<T>(val data: T) : UiState
        data class Error(val message: String, val recoverable: Boolean = true) : UiState
    }
}

class ViewModelFactory @Inject constructor(
    private val creators: Map<Class<out ViewModel>, @JvmSuppressWildcards Provider<ViewModel>>
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        val creator = creators[modelClass] ?: creators.entries.firstOrNull {
            modelClass.isAssignableFrom(it.key)
        }?.value ?: throw IllegalArgumentException("Unknown ViewModel class: $modelClass")
        return creator.get() as T
    }
}
