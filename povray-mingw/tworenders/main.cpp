// Repro/verification harness mirroring src/viewer.cpp's VFE integration:
// one BppVfeSession reused across renders, weak_ptr<BppVfeDisplay>
// re-acquired lazily via GetDisplay(), and now also exercising the
// "F6 while rendering cancels and restarts" flow (CancelRender() mid-render,
// wait for stRenderShutdown, then SetOptions()/StartRender() again on the
// same session -- matching startVfeQuickRender()'s _vfeRestartPending path).
//
// Usage: tworenders.exe <scene.pov> +W320 +H240 +Oout.png [more args...]

#include "base/version_info.h"
#include "backend/povray.h"
#include "vfe.h"

#include "bppvfesession.h"
#include "bppvfedisplay.h"

#include <memory>

using namespace vfe;
using namespace vfePlatform;

static void PrintStatus(vfeSession *session)
{
  std::string str;
  vfeSession::MessageType type;
  while (session->GetNextCombinedMessage(type, str))
    fprintf(stderr, "%s\n", str.c_str());
}

// Runs one render. If cancelAfterNPolls > 0, calls CancelRender() partway
// through instead of letting it finish naturally.
static bool RunOneRender(BppVfeSession *session, int argc, char **argv, int iteration, int cancelAfterNPolls)
{
  fprintf(stderr, "\n=== iteration %d: building options (cancelAfterNPolls=%d) ===\n", iteration, cancelAfterNPolls);

  std::weak_ptr<BppVfeDisplay> display;
  display.reset();

  vfeRenderOptions opts;
  char *s;
  if ((s = std::getenv("POVINC")) != nullptr)
    opts.AddLibraryPath(s);
  for (int i = 0; i < argc; ++i)
    opts.AddCommand(argv[i]);

  if (session->SetOptions(opts) != vfeNoError)
  {
    fprintf(stderr, "SetOptions failed: %s\n", session->GetErrorString());
    return false;
  }

  if (session->StartRender() != vfeNoError)
  {
    fprintf(stderr, "StartRender failed: %s\n", session->GetErrorString());
    return false;
  }

  vfeStatusFlags flags;
  int polls = 0;
  bool cancelled = false;
  while (((flags = session->GetStatus(true, 20)) & stRenderShutdown) == 0)
  {
    PrintStatus(session);
    ++polls;

    if (display.expired())
      display = std::dynamic_pointer_cast<BppVfeDisplay>(session->GetDisplay());

    if (auto d = display.lock())
    {
      if (d->dirty())
      {
        QImage snap = d->snapshot();
        (void)snap;
      }
    }

    if (cancelAfterNPolls > 0 && polls >= cancelAfterNPolls && !cancelled)
    {
      fprintf(stderr, "[iteration %d] calling CancelRender() after %d polls\n", iteration, polls);
      int rc = session->CancelRender();
      fprintf(stderr, "[iteration %d] CancelRender() returned %d\n", iteration, rc);
      cancelled = true;
    }
  }
  PrintStatus(session);

  fprintf(stderr, "=== iteration %d: done, failed=%d, cancelled=%d ===\n", iteration, (int)session->Failed(), (int)cancelled);
  return true; // a cancelled render "failing" is expected, not a test failure
}

int main(int argc, char **argv)
{
  BppVfeSession *session = new BppVfeSession();

  session->SetDisplayCreator(
      [](unsigned int w, unsigned int h, vfeSession *s, bool visible) -> vfeDisplay * {
        return new BppVfeDisplay(w, h, s, visible);
      });

  if (session->Initialize(nullptr, nullptr) != vfeNoError)
  {
    fprintf(stderr, "Initialize failed: %s\n", session->GetErrorString());
    return 1;
  }

  // Render 1: cancel it partway through (simulates F6 pressed again while rendering).
  bool ok1 = RunOneRender(session, argc - 1, argv + 1, 1, /*cancelAfterNPolls=*/2);
  fprintf(stderr, "\n########## first render (cancelled) %s, restarting ##########\n\n", ok1 ? "OK" : "FAILED");

  // Render 2: the "restart" -- same session, immediately after the cancelled one's stRenderShutdown.
  bool ok2 = RunOneRender(session, argc - 1, argv + 1, 2, /*cancelAfterNPolls=*/0);
  fprintf(stderr, "\n########## restarted render %s ##########\n\n", ok2 ? "OK" : "FAILED");

  // Render 3: one more normal render on the same session, to make sure the
  // cancel+restart cycle didn't leave anything wedged.
  bool ok3 = RunOneRender(session, argc - 1, argv + 1, 3, /*cancelAfterNPolls=*/0);
  fprintf(stderr, "\n########## third render %s ##########\n\n", ok3 ? "OK" : "FAILED");

  session->Shutdown();
  delete session;

  return (ok1 && ok2 && ok3) ? 0 : 1;
}
