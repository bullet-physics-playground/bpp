#include "bppvfesession.h"

#if USE_VFE

#include <string>

BppVfeSession::BppVfeSession(int id) : vfePlatform::vfeWinSession(id) {}

void BppVfeSession::NotifyCriticalError(const char *message, const char *file, int line) {
  AppendErrorAndStatusMessage(std::string(message) + " (" + file + ":" + std::to_string(line) + ")");
}

namespace pov_frontend {
bool MinimizeShellouts(void) { return true; }
bool ShelloutsPermitted(void) { return false; }
}
// end of namespace pov_frontend

#endif // USE_VFE
