/**
 * @file bppvfesession.cpp
 * @brief Implementation of bpp's POV-Ray VFE session and its shellout policy.
 */

#include "bppvfesession.h"

#if USE_VFE

#include <string>

BppVfeSession::BppVfeSession(int id) : BppVfeSessionBase(id) {}

void BppVfeSession::NotifyCriticalError(const char *message, const char *file, int line) {
  AppendErrorAndStatusMessage(std::string(message) + " (" + file + ":" + std::to_string(line) + ")");
}

namespace pov_frontend {
/**
 * @brief Tells POV-Ray to keep shellout processing to a minimum.
 *
 * POV-Ray requires an embedding front end to define this; it is not a bpp
 * function that anything here calls.
 *
 * @return Always true.
 */
bool MinimizeShellouts(void) { return true; }

/**
 * @brief Tells POV-Ray that scenes may not run shell commands.
 *
 * A scene bpp exported should never execute anything, so the shellout feature
 * is refused outright. Also required by POV-Ray of an embedding front end.
 *
 * @return Always false.
 */
bool ShelloutsPermitted(void) { return false; }
}
// end of namespace pov_frontend

#endif // USE_VFE
