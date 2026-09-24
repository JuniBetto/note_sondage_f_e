// Retain the original native benchmark command. The shared implementation
// lives under test/ because Chrome's test server cannot serve files outside it.
import '../test/support/chat_cache_benchmark.dart' as benchmark;

void main() => benchmark.main();
