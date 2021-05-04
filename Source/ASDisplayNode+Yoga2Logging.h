#if defined(__cplusplus)

#import <AsyncDisplayKit/ASAvailability.h>

#if YOGA

#include <cstdarg>

#import YOGA_HEADER_PATH

/**
 * Implements the YGConfig logging function. Yoga logging is actually a bit
 * tricky in a multithreaded environment, so this gets its own source file.
 */
namespace AS {
namespace Yoga2 {
namespace Logging {
/**
 * Note: Don't set a print func on yoga nodes. See details in the implementation
 * of Log, or at https://github.com/facebook/yoga/issues/879
 */

/**
 * The log callback to be provided to Yoga.
 */
int Log(const YGConfigRef config, const YGNodeRef node, YGLogLevel level,
        const char *format, va_list args);

}  // namespace Logging
}  // namespace Yoga2
}  // namespace AS

#endif  // YOGA

#endif  // defined(__cplusplus)
