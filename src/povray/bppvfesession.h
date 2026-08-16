#ifndef BPPVFESESSION_H
#define BPPVFESESSION_H

#if USE_VFE

#include "vfeplatform.h"

class BppVfeSession : public vfePlatform::vfeWinSession {
public:
  BppVfeSession(int id = 0);

  virtual void NotifyCriticalError(const char *message, const char *file, int line) override;
};

#endif // USE_VFE

#endif // BPPVFESESSION_H
