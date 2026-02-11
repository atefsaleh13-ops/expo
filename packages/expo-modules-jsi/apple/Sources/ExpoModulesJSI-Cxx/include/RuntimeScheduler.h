#pragma once

#ifdef __cplusplus

#include <memory>
#include <swift/bridging>
#include <jsi/jsi.h>
#include <react/renderer/runtimescheduler/RuntimeScheduler.h>
#include <react/renderer/runtimescheduler/RuntimeSchedulerBinding.h>

namespace jsi = facebook::jsi;
namespace react = facebook::react;

namespace expo {

std::shared_ptr<react::RuntimeScheduler> runtimeSchedulerFromRuntime(jsi::Runtime &runtime) {
  if (auto binding = react::RuntimeSchedulerBinding::getBinding(runtime)) {
    return binding->getRuntimeScheduler();
  }
  return nullptr;
}

/**
 Wrapper for RuntimeScheduler from React which for some reason cannot be constructed from Swift.
 */
class RuntimeScheduler {
private:
  std::shared_ptr<react::RuntimeScheduler> reactRuntimeScheduler;

public:
  RuntimeScheduler(jsi::Runtime &runtime) : reactRuntimeScheduler(runtimeSchedulerFromRuntime(runtime)) {}

  using ScheduleTaskCallback = void(^)();

  void scheduleTask(react::SchedulerPriority priority, ScheduleTaskCallback callback) noexcept {
    reactRuntimeScheduler->scheduleTask(priority, [callback = std::move(callback)](jsi::Runtime &runtime) {
      callback();
    });
  }
} SWIFT_UNSAFE_REFERENCE; // class RuntimeScheduler

} // namespace expo

#endif // __cplusplus
