#import <AsyncDisplayKit/ASAvailability.h>

#if YOGA

#import <AsyncDisplayKit/ASDisplayNode+Yoga2Logging.h>

#import <AsyncDisplayKit/ASDisplayNode+Yoga2.h>

#import <AsyncDisplayKit/ASLog.h>
#import <dispatch/dispatch.h>

namespace AS {
namespace Yoga2 {
namespace Logging {

/// The maximum length for a log chunk. If Yoga goes over, we just log an error.
constexpr size_t kChunkCapacity = 128;

/// The destructor for the pthread_specific key for the preamble.
void PreambleStorageDestructor(void *ptr) { delete reinterpret_cast<std::string *>(ptr); }

/**
 * Get a thread-local std::string buffer for the preamble of a multipart yoga log statement.
 *
 * Most Yoga log statements (gPrintChanges) actually come in three phases:
 * - A preamble, e.g. "{1."
 * - A YGNodePrint, which we would turn into "<ASTextNode2: 0xFFFFFFFF>"
 * - An ending, e.g. "} d: 100 200"
 *
 * Especially since we're multithreaded, this does not work for us. It causes interleaving of log
 * statements. Additionally it causes extra log metadata to be spat out with each phase and breaks
 * up the lines. So when we detect this pattern, we use this thread-local buffer to store the
 * prefix, we _do not implement_ YGNodePrint, and then when the ending comes through we combine all
 * three pieces. Details at https://github.com/facebook/yoga/issues/879
 */
std::string *GetPreambleStorage() {
  static pthread_key_t key;
  static dispatch_once_t once_token;
  dispatch_once(&once_token, ^{
    key = pthread_key_create(&key, PreambleStorageDestructor);
  });

  auto str = reinterpret_cast<std::string *>(pthread_getspecific(key));
  if (!str) {
    str = new std::string;
    pthread_setspecific(key, str);
  }
  return str;
}

inline os_log_type_t OSTypeFromYogaLevel(YGLogLevel level) {
  switch (level) {
    case YGLogLevelInfo:
    case YGLogLevelWarn:
      return OS_LOG_TYPE_INFO;
    case YGLogLevelVerbose:
    case YGLogLevelDebug:
      return OS_LOG_TYPE_DEBUG;
    case YGLogLevelError:
    case YGLogLevelFatal:
      // Note: yoga will issue abort() after fatal logs.
      return OS_LOG_TYPE_ERROR;
  }
}

int Log(const YGConfigRef config, const YGNodeRef node, YGLogLevel level, const char *format,
        va_list args) {
  if (!ASEnableVerboseLogging && level == YGLogLevelVerbose) {
    return 0;
  }
  os_log_type_t os_type = OSTypeFromYogaLevel(level);

  // If this log type isn't enabled right now, bail.
  if (!os_log_type_enabled(ASLayoutLog(), os_type)) {
    return 0;
  }

  char c[kChunkCapacity];
  int str_size = vsnprintf(c, kChunkCapacity, format, args);
  if (str_size < 0 || str_size >= kChunkCapacity) {
    ASDisplayNodeCFailAssert(@"Yoga log chunk over capacity!");
    return 0;
  }

  bool has_open_brace = (strchr(c, '{') != nullptr);
  bool has_close_brace = (strchr(c, '}') != nullptr);
  if (has_open_brace && !has_close_brace) {
    // This is the preamble. Store it in our TLS buffer and wait for the rest.
    std::string *preamble = GetPreambleStorage();
    ASDisplayNodeCAssert(preamble->empty(), @"Two Yoga log preambles in a row.");
    preamble->assign(c);
  } else if (!has_open_brace && has_close_brace) {
    // This is the end. Combine the parts and log them with the node.
    std::string preamble;
    preamble.swap(*GetPreambleStorage());
    os_log_with_type(ASLayoutLog(), os_type, "%s %@ %s", preamble.c_str(),
                     ASObjectDescriptionMakeTiny(GetTexture(node)), c);

  } else {
    // This is a normal one-shot message. Just log it.
    os_log_with_type(ASLayoutLog(), os_type, "%s", c);
  }
  // Always report that we printed the whole string.
  return str_size;
}

}  // namespace Logging
}  // namespace Yoga2
}  // namespace AS

#endif  // YOGA
