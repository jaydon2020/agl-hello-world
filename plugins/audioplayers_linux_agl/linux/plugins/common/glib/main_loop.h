// Stub for ivi-homescreen's plugin_common_glib::MainLoop
// In standard Flutter Linux desktop, the GLib main loop is already running
// via GTK, so we just need a no-op singleton.
#pragma once

#include <glib.h>

namespace plugin_common_glib {

class MainLoop {
 public:
  static MainLoop& GetInstance() {
    static MainLoop instance;
    return instance;
  }

 private:
  MainLoop() = default;
};

}  // namespace plugin_common_glib
