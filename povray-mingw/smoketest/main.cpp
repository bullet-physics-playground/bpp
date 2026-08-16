// Build-first smoke test for the povvfe static library (Phase 0 of the VFE
// embedding prototype). Ported near-verbatim from
// povray/vfe/win/console/winconsole.cpp -- see ../README.md for context.
//
// Usage: smoketest.exe <scene.pov> +W320 +H240 +Oout.png [more povray args...]

#include "base/version_info.h"

#include "backend/povray.h"

#include "vfe.h"

#include "bppvfesession.h"
#include "bppvfedisplay.h"

#ifndef _CONSOLE
#error "You must define _CONSOLE in windows/povconfig/syspovconfig.h prior to building the console version, otherwise you will get link errors."
#endif

using namespace vfe;
using namespace vfePlatform;

void PrintStatus(vfeSession *session)
{
  std::string str;
  vfeSession::MessageType type;
  static vfeSession::MessageType lastType = vfeSession::mUnclassified;

  while (session->GetNextCombinedMessage(type, str))
  {
    if (type != vfeSession::mGenericStatus)
    {
      if (lastType == vfeSession::mGenericStatus)
        fprintf(stderr, "\n");
      fprintf(stderr, "%s\n", str.c_str());
    }
    else
      fprintf(stderr, "%s\r", str.c_str());
    lastType = type;
  }
}

void ErrorExit(vfeSession *session)
{
  fprintf(stderr, "%s\n", session->GetErrorString());
  session->Shutdown();
  delete session;
  exit(1);
}

int main(int argc, char **argv)
{
  char             *s;
  BppVfeSession    *session = new BppVfeSession();
  vfeStatusFlags    flags;
  vfeRenderOptions  opts;
  BppVfeDisplay    *display = nullptr;

  session->SetDisplayCreator(
      [&display](unsigned int w, unsigned int h, vfeSession *s, bool visible) -> vfeDisplay * {
        display = new BppVfeDisplay(w, h, s, visible);
        return display;
      });

  fprintf(stderr,
          "bpp povvfe smoketest -- minimal console build of POV-Ray VFE under MinGW.\n\n"
          "Persistence of Vision(tm) Ray Tracer Version " POV_RAY_VERSION_INFO ".\n"
          DISTRIBUTION_MESSAGE_1 "\n"
          DISTRIBUTION_MESSAGE_2 "\n"
          DISTRIBUTION_MESSAGE_3 "\n"
          POV_RAY_COPYRIGHT "\n"
          DISCLAIMER_MESSAGE_1 "\n"
          DISCLAIMER_MESSAGE_2 "\n\n");

  if (session->Initialize(nullptr, nullptr) != vfeNoError)
    ErrorExit(session);

  if ((s = std::getenv("POVINC")) != nullptr)
    opts.AddLibraryPath(s);
  while (*++argv)
    opts.AddCommand(*argv);

  if (session->SetOptions(opts) != vfeNoError)
    ErrorExit(session);
  if (session->StartRender() != vfeNoError)
    ErrorExit(session);

  while (((flags = session->GetStatus(true, 250)) & stRenderShutdown) == 0)
  {
    PrintStatus(session);
    if (display && display->dirty())
    {
      QImage snap = display->snapshot();
      int nonBlack = 0;
      for (int y = 0; y < snap.height(); ++y)
      {
        const uchar *row = snap.constScanLine(y);
        for (int x = 0; x < snap.width(); ++x)
          if (row[x * 4] != 0 || row[x * 4 + 1] != 0 || row[x * 4 + 2] != 0)
            ++nonBlack;
      }
      fprintf(stderr, "[BppVfeDisplay] pixels rendered (session): %d/%d, non-black pixels in snapshot: %d\n",
              session->GetPixelsRendered(), session->GetTotalPixels(), nonBlack);
    }
  }
  session->Shutdown();
  PrintStatus(session);

  bool failed = session->Failed();
  delete session;

  return failed ? 1 : 0;
}
