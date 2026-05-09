#pragma once
#include <stdint.h>
#include <stdbool.h>

#ifndef __clang__
  #ifndef _Nonnull
    #define _Nonnull
  #endif
  #ifndef _Nullable
    #define _Nullable
  #endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

/// Function pointer type for Swift job callbacks
typedef void (*qt_wakeup_callback_t)(void* _Nullable context);

void qt_event_loop_prepare_main_thread(void);

/// Schedules a wakeup on the Qt main thread immediately (QueuedConnection).
void qt_event_loop_wake_main(qt_wakeup_callback_t _Nonnull callback, void* _Nullable context);

/// Schedules a wakeup after a delay (via QTimer).
void qt_event_loop_wake_after(qt_wakeup_callback_t _Nonnull callback, void* _Nullable context, int ms);

/// Returns true if the calling thread is the Qt main thread.
bool qt_is_main_thread(void);


void qt_thread_pool_submit(qt_wakeup_callback_t _Nonnull callback, void* _Nullable context, int priority);

/// Requests the Qt application to quit.
void qt_event_loop_quit(void);

#ifdef __cplusplus
}
#endif