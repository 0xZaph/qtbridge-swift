// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#pragma once

#include <QtCore/qobject.h>
#include <QtQml/qqmllist.h>

#include "swiftobjectaccesor.h"

class QObjectProxyImpl : public QObject,
                         public SwiftObjectAccesor
{
    Q_OBJECT
    Q_CLASSINFO("DefaultProperty", "children")
    Q_PROPERTY(QQmlListProperty<QObject> children READ children CONSTANT)

public:
    QObjectProxyImpl(void *swiftObj)
    : m_swiftObj(swiftObj)
    {}

    using DeleterFn = void(*)(void *swiftObj);
    QObjectProxyImpl(void *swiftObj, DeleterFn deleter)
        : m_swiftObj(swiftObj),
          m_deleter(deleter)
    {}

    ~QObjectProxyImpl();

    void* swiftObject() const final;

    QQmlListProperty<QObject> children();

private:
    QList<QObject *> m_children;

    void* m_swiftObj = nullptr;
    DeleterFn m_deleter = nullptr;
};
