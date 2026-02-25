// Stub for ivi-homescreen's plugin_common::Encodable utilities
// Provides a no-op PrintFlutterEncodableValue for standard Flutter desktop.
#pragma once

#include <flutter/encodable_value.h>
#include <string>

namespace plugin_common {

class Encodable {
 public:
  static void PrintFlutterEncodableValue(const std::string& /* label */,
                                          const flutter::EncodableValue& /* value */) {
    // No-op in standard Flutter desktop builds
  }
};

}  // namespace plugin_common
