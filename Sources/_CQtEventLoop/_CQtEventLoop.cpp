// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

#include "_CQtEventLoop.h"
#include <QtCore/QCoreApplication>
#include <QtCore/QMetaObject>
#include <QtCore/QThread>
#include <QtCore/QTimer>
#include <QtCore/QThreadPool>
#include <QtCore/QPointer>

static QThread* mainThreadPtr = nullptr;

extern "C" {

void qt_event_loop_prepare_main_thread(void) {
    // If we haven't captured it yet, capture the current thread.
    // This is called from the Swift side during startup.
    if (!mainThreadPtr) {
        mainThreadPtr = QThread::currentThread();
    }
}

void qt_event_loop_wake_main(qt_wakeup_callback_t callback, void* context) {
    auto *app = QCoreApplication::instance();
    if (!app) {
        callback(context);
        return;
    }

    QMetaObject::invokeMethod(app, [callback, context]() {
        callback(context);
    }, Qt::QueuedConnection);
}

void qt_event_loop_wake_after(qt_wakeup_callback_t callback, void* context, int ms) {
    auto *app = QCoreApplication::instance();
    if (!app) {
        callback(context);
        return;
    }

    QMetaObject::invokeMethod(app, [callback, context, ms, app]() {
        QTimer::singleShot(ms, app, [callback, context]() {
            callback(context);
        });
    }, Qt::QueuedConnection);
}

void qt_thread_pool_submit(qt_wakeup_callback_t callback, void* context, int priority) {
    auto *app = QCoreApplication::instance();
    if (!app) {
        callback(context);
        return;
    }

    QThreadPool::globalInstance()->start([callback, context]() {
        callback(context);
    }, priority);
}

bool qt_is_main_thread(void) {
    if (mainThreadPtr) return QThread::currentThread() == mainThreadPtr;
    auto *app = QCoreApplication::instance();
    if (!app) return false;
    return QThread::currentThread() == app->thread();
}

void qt_event_loop_quit(void) {
    if (auto *app = QCoreApplication::instance()) {
        app->quit();
    }
}

} // extern "C"