// POV-Ray's Windows VFE platform code (vfe/win/vfeplatform.cpp) calls
// pov_frontend::MinimizeShellouts() and pov_frontend::ShelloutsPermitted(),
// which upstream defines in vfe/win/console/winconsole.cpp. That file also
// contains a console main(), so it cannot be linked into libpovvfe (the host
// application provides its own main/entry point). This shim supplies just the
// two symbols, matching winconsole.cpp's placeholder behaviour.
namespace pov_frontend
{
    bool MinimizeShellouts(void) { return false; }
    bool ShelloutsPermitted(void) { return false; }
}
