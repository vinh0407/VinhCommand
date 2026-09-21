class OpencodeProvider {
  final String id;
  final String name;
  final String description;
  final bool hasFreeModels;

  const OpencodeProvider({
    required this.id,
    required this.name,
    required this.description,
    this.hasFreeModels = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'hasFreeModels': hasFreeModels,
  };

  factory OpencodeProvider.fromJson(Map<String, dynamic> json) => OpencodeProvider(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    hasFreeModels: json['hasFreeModels'] as bool? ?? true,
  );
}

class OpencodeModel {
  final String id;
  final String providerId;
  final String displayName;
  final bool isFree;
  final String description;

  const OpencodeModel({
    required this.id,
    required this.providerId,
    required this.displayName,
    required this.isFree,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'providerId': providerId,
    'displayName': displayName,
    'isFree': isFree,
    'description': description,
  };

  factory OpencodeModel.fromJson(Map<String, dynamic> json) => OpencodeModel(
    id: json['id'] as String? ?? '',
    providerId: json['providerId'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    isFree: json['isFree'] as bool? ?? false,
    description: json['description'] as String? ?? '',
  );
}

const List<OpencodeProvider> kDefaultOpencodeProviders = [
  OpencodeProvider(
    id: 'zenmux',
    name: 'ZenMux',
    description: 'ZenMux Aggregator (Free & High-Performance Models)',
    hasFreeModels: true,
  ),
  OpencodeProvider(
    id: 'kilo',
    name: 'Kilo Gateway',
    description: 'Kilo AI Gateway (Diverse Free Reasoning & Coding Models)',
    hasFreeModels: true,
  ),
  OpencodeProvider(
    id: 'opencode',
    name: 'OpenCode Zen',
    description: 'OpenCode Native Gateway (Official Free Coding Models)',
    hasFreeModels: true,
  ),
];

const List<OpencodeModel> kDefaultOpencodeModels = [
  // ZenMux - Free models first
  OpencodeModel(
    id: 'zenmux/z-ai/glm-4.6v-flash-free',
    providerId: 'zenmux',
    displayName: 'GLM-4.6v Flash (Free)',
    isFree: true,
    description: 'Ultra-fast vision & code generation',
  ),
  OpencodeModel(
    id: 'zenmux/z-ai/glm-4.7-flash-free',
    providerId: 'zenmux',
    displayName: 'GLM-4.7 Flash (Free)',
    isFree: true,
    description: 'Next-gen fast code generation',
  ),
  OpencodeModel(
    id: 'zenmux/z-ai/glm-5.2-free',
    providerId: 'zenmux',
    displayName: 'GLM-5.2 (Free)',
    isFree: true,
    description: 'High-capability reasoning & logic',
  ),
  OpencodeModel(
    id: 'zenmux/moonshotai/kimi-k3-free',
    providerId: 'zenmux',
    displayName: 'Kimi K3 (Free)',
    isFree: true,
    description: 'Moonshot long-context code understanding',
  ),
  OpencodeModel(
    id: 'zenmux/moonshotai/kimi-k2.7-code-free',
    providerId: 'zenmux',
    displayName: 'Kimi K2.7 Code (Free)',
    isFree: true,
    description: 'Specialized for code review and refactoring',
  ),
  OpencodeModel(
    id: 'zenmux/stepfun/step-3.7-flash-free',
    providerId: 'zenmux',
    displayName: 'Step 3.7 Flash (Free)',
    isFree: true,
    description: 'High-efficiency fast code model',
  ),
  OpencodeModel(
    id: 'zenmux/anthropic/claude-sonnet-5-free',
    providerId: 'zenmux',
    displayName: 'Claude Sonnet 5 (Free)',
    isFree: true,
    description: 'State of the art reasoning & code',
  ),
  // ZenMux - Standard / Pro models
  OpencodeModel(
    id: 'zenmux/z-ai/glm-5.2',
    providerId: 'zenmux',
    displayName: 'GLM-5.2 (Pro)',
    isFree: false,
    description: 'Standard GLM-5.2',
  ),
  OpencodeModel(
    id: 'zenmux/moonshotai/kimi-k3',
    providerId: 'zenmux',
    displayName: 'Kimi K3 (Pro)',
    isFree: false,
    description: 'Full Kimi K3 instance',
  ),
  OpencodeModel(
    id: 'zenmux/deepseek/deepseek-v3.2',
    providerId: 'zenmux',
    displayName: 'DeepSeek V3.2',
    isFree: false,
    description: 'DeepSeek coding & math reasoning',
  ),
  OpencodeModel(
    id: 'zenmux/google/gemini-2.5-flash',
    providerId: 'zenmux',
    displayName: 'Gemini 2.5 Flash',
    isFree: false,
    description: 'Google multimodal flash',
  ),
  OpencodeModel(
    id: 'zenmux/openai/gpt-5',
    providerId: 'zenmux',
    displayName: 'GPT-5',
    isFree: false,
    description: 'OpenAI GPT-5 flagship',
  ),

  // Kilo Gateway - Free models first
  OpencodeModel(
    id: 'kilo/poolside/laguna-xs-2.1:free',
    providerId: 'kilo',
    displayName: 'Laguna XS 2.1 (Free)',
    isFree: true,
    description: 'Poolside high-speed code model',
  ),
  OpencodeModel(
    id: 'kilo/poolside/laguna-s-2.1:free',
    providerId: 'kilo',
    displayName: 'Laguna S 2.1 (Free)',
    isFree: true,
    description: 'Poolside standard code model',
  ),
  OpencodeModel(
    id: 'kilo/stepfun/step-3.7-flash:free',
    providerId: 'kilo',
    displayName: 'Step 3.7 Flash (Free)',
    isFree: true,
    description: 'StepFun flash reasoning model',
  ),
  OpencodeModel(
    id: 'kilo/thinkingmachines/inkling-small:free',
    providerId: 'kilo',
    displayName: 'Inkling Small (Free)',
    isFree: true,
    description: 'ThinkingMachines lightweight code assistant',
  ),
  OpencodeModel(
    id: 'kilo/liquid/lfm-2.5-2.6b:free',
    providerId: 'kilo',
    displayName: 'LFM 2.5 2.6B (Free)',
    isFree: true,
    description: 'Liquid AI ultra-compact neural network',
  ),
  OpencodeModel(
    id: 'kilo/nex-agi/nex-n2.5-mini:free',
    providerId: 'kilo',
    displayName: 'NEX N2.5 Mini (Free)',
    isFree: true,
    description: 'NEX AGI compact reasoning',
  ),
  OpencodeModel(
    id: 'kilo/nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free',
    providerId: 'kilo',
    displayName: 'Nemotron 3 Nano Reasoning (Free)',
    isFree: true,
    description: 'NVIDIA 30B reasoning model',
  ),
  OpencodeModel(
    id: 'kilo/nvidia/nemotron-3-super-120b-a12b:free',
    providerId: 'kilo',
    displayName: 'Nemotron 3 Super 120B (Free)',
    isFree: true,
    description: 'NVIDIA 120B large reasoning model',
  ),
  OpencodeModel(
    id: 'kilo/nvidia/nemotron-3-ultra-550b-a55b:free',
    providerId: 'kilo',
    displayName: 'Nemotron 3 Ultra 550B (Free)',
    isFree: true,
    description: 'NVIDIA 550B ultra reasoning model',
  ),
  OpencodeModel(
    id: 'kilo/nvidia/nemotron-3.5-lightning:free',
    providerId: 'kilo',
    displayName: 'Nemotron 3.5 Lightning (Free)',
    isFree: true,
    description: 'NVIDIA lightning-fast code model',
  ),
  OpencodeModel(
    id: 'kilo/qwen/qwen3.8-27b:free',
    providerId: 'kilo',
    displayName: 'Qwen 3.8 27B (Free)',
    isFree: true,
    description: 'Alibaba Qwen 3.8 coding model',
  ),
  OpencodeModel(
    id: 'kilo/z-ai/glm-5.2:free',
    providerId: 'kilo',
    displayName: 'GLM-5.2 (Free)',
    isFree: true,
    description: 'Z-AI GLM-5.2 via Kilo',
  ),
  // Kilo Gateway - Standard models
  OpencodeModel(
    id: 'kilo/qwen/qwen3.8-max-0902',
    providerId: 'kilo',
    displayName: 'Qwen 3.8 Max',
    isFree: false,
    description: 'Qwen 3.8 flagship model',
  ),
  OpencodeModel(
    id: 'kilo/sakana/fugu-max',
    providerId: 'kilo',
    displayName: 'Fugu Max',
    isFree: false,
    description: 'Sakana AI Fugu model',
  ),
  OpencodeModel(
    id: 'kilo/openai/gpt-4o-mini',
    providerId: 'kilo',
    displayName: 'GPT-4o Mini',
    isFree: false,
    description: 'OpenAI GPT-4o Mini via Kilo',
  ),

  // OpenCode Zen - Free models first
  OpencodeModel(
    id: 'opencode/ling-3.0-flash-fin-free',
    providerId: 'opencode',
    displayName: 'Ling 3.0 Flash Fin (Free)',
    isFree: true,
    description: 'High precision code & logic',
  ),
  OpencodeModel(
    id: 'opencode/mimo-v2.5-free',
    providerId: 'opencode',
    displayName: 'Mimo v2.5 (Free)',
    isFree: true,
    description: 'Xiaomi Mimo multi-lingual code model',
  ),
  OpencodeModel(
    id: 'opencode/muse-spark-1.2-contributor-free',
    providerId: 'opencode',
    displayName: 'Muse Spark 1.2 (Free)',
    isFree: true,
    description: 'OpenCode contributor free model',
  ),
  OpencodeModel(
    id: 'opencode/muse-spark-1.3-contributor-free',
    providerId: 'opencode',
    displayName: 'Muse Spark 1.3 (Free)',
    isFree: true,
    description: 'Next-generation contributor free model',
  ),
  OpencodeModel(
    id: 'opencode/nemotron-3-ultra-free',
    providerId: 'opencode',
    displayName: 'Nemotron 3 Ultra (Free)',
    isFree: true,
    description: 'NVIDIA ultra free model',
  ),
  OpencodeModel(
    id: 'opencode/nemotron-3.5-lightning-free',
    providerId: 'opencode',
    displayName: 'Nemotron 3.5 Lightning (Free)',
    isFree: true,
    description: 'NVIDIA lightning free model',
  ),
  // OpenCode Zen - Standard models
  OpencodeModel(
    id: 'opencode/deepseek-v4-flash',
    providerId: 'opencode',
    displayName: 'DeepSeek V4 Flash',
    isFree: false,
    description: 'DeepSeek V4 flash model',
  ),
  OpencodeModel(
    id: 'opencode/gemini-3-flash',
    providerId: 'opencode',
    displayName: 'Gemini 3 Flash',
    isFree: false,
    description: 'Google Gemini 3 Flash',
  ),
  OpencodeModel(
    id: 'opencode/gpt-5',
    providerId: 'opencode',
    displayName: 'GPT-5',
    isFree: false,
    description: 'OpenAI GPT-5 via OpenCode Zen',
  ),
  OpencodeModel(
    id: 'opencode/kimi-k3',
    providerId: 'opencode',
    displayName: 'Kimi K3',
    isFree: false,
    description: 'Moonshot Kimi K3',
  ),
];
