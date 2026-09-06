/// Global application constants.
///
/// These values are referenced throughout the codebase to ensure consistency.
/// Change here, change everywhere.
library;

// ---------------------------------------------------------------------------
// AI / RAG pipeline
// ---------------------------------------------------------------------------

/// Target token count per text chunk during ingestion.
const int kChunkTokenSize = 512;

/// Token overlap between consecutive chunks (preserves cross-boundary context).
const int kChunkTokenOverlap = 64;

/// Embedding vector dimension produced by all-MiniLM-L6-v2.
const int kEmbeddingDimension = 384;

/// KNN retrieval count: top-K chunks returned by the vector store.
const int kRagTopK = 5;

/// Minimum cosine similarity for a chunk to pass the relevance gate.
/// Queries where no chunk meets this threshold skip the LLM and return
/// the no-answer fallback message.
const double kRelevanceThreshold = 0.35;

/// Maximum tokens the LLM is asked to generate per response.
const int kDefaultMaxTokens = 512;

/// Reduced token budget applied when thermal throttling is detected.
const int kThrottledMaxTokens = 256;

/// LLM temperature (low = more deterministic, appropriate for tutoring).
const double kDefaultTemperature = 0.2;

/// LLM top-P nucleus sampling parameter.
const double kDefaultTopP = 0.9;

/// Maximum context window size (tokens) for the KV cache.
const int kLlmContextWindow = 2048;

/// Maximum prompt length in tokens (leaves room for generation within context).
const int kMaxPromptTokens = 1600;

/// Query debounce duration to avoid rapid re-generation.
const Duration kQueryDebounce = Duration(milliseconds: 500);

// ---------------------------------------------------------------------------
// Conversation / session
// ---------------------------------------------------------------------------

/// Maximum number of prior turns retained in the conversation context.
const int kMaxConversationTurns = 5;

// ---------------------------------------------------------------------------
// Ingestion
// ---------------------------------------------------------------------------

/// Maximum file size accepted for upload ingestion (50 MB in bytes).
const int kMaxUploadSizeBytes = 50 * 1024 * 1024;

/// Maximum duration allowed for ingesting a ≤50 MB document.
const Duration kIngestionTimeout = Duration(seconds: 30);

// ---------------------------------------------------------------------------
// Storage
// ---------------------------------------------------------------------------

/// How long the storage report is cached before a fresh stat() scan.
const Duration kStorageReportCacheDuration = Duration(seconds: 30);

// ---------------------------------------------------------------------------
// Performance targets
// ---------------------------------------------------------------------------

/// App cold-start-to-home-screen target on minimum-spec hardware.
const Duration kColdStartTarget = Duration(seconds: 10);

/// Maximum time for the Tutor to return first token after a query.
const Duration kTutorResponseTarget = Duration(seconds: 30);

/// Maximum time for ContentManager.openSection to return.
const Duration kSectionOpenTarget = Duration(seconds: 2);

/// Maximum time for StorageManager.getStorageReport to return.
const Duration kStorageReportTarget = Duration(seconds: 2);

// ---------------------------------------------------------------------------
// Bcrypt cost factors
// ---------------------------------------------------------------------------

/// Cost factor used when hashing account passwords.
const int kBcryptCostPassword = 12;

/// Cost factor used when hashing supervisor PINs.
const int kBcryptCostPin = 12;

// ---------------------------------------------------------------------------
// Database file names
// ---------------------------------------------------------------------------

/// Primary application database (accounts, progress, metadata).
const String kAppDbName = 'app.db';

/// Corpus database (chunks + vector index).
const String kCorpusDbName = 'corpus.db';

// ---------------------------------------------------------------------------
// Asset paths
// ---------------------------------------------------------------------------

/// Default LLM model file path (relative to app support directory).
const String kDefaultModelFileName = 'qwen2.5-3b-q4_k_m.gguf';

/// Embedding model asset path.
const String kEmbeddingModelAssetPath = 'assets/models/embedding/all-minilm-l6-v2.onnx';

// ---------------------------------------------------------------------------
// Supported locales
// ---------------------------------------------------------------------------

/// BCP 47 language tags for all supported UI locales.
const List<String> kSupportedLocaleCodes = ['en', 'hi', 'ta', 'te', 'kn', 'bn'];

// ---------------------------------------------------------------------------
// Content tracks
// ---------------------------------------------------------------------------

const String kTrackCbse = 'cbse';
const String kTrackJee = 'jee';
const String kTrackNeet = 'neet';
const String kTrackUpsc = 'upsc';
const String kTrackSsc = 'ssc';

/// Valid CBSE class levels.
const List<int> kCbseClassLevels = [6, 7, 8, 9, 10, 11, 12];

// ---------------------------------------------------------------------------
// Key-value store keys
// ---------------------------------------------------------------------------

/// Key for the persisted locale preference in key_value_store.
const String kKvKeyLocale = 'app_locale';

/// Key for the last session heartbeat timestamp.
const String kKvKeyLastHeartbeat = 'last_heartbeat_ms';

// ---------------------------------------------------------------------------
// flutter_secure_storage key prefixes
// ---------------------------------------------------------------------------

/// Prefix for session token keys, namespaced by accountId.
/// Full key: '$kSessionTokenPrefix$accountId'
const String kSessionTokenPrefix = 'session_token_';
