// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#pragma once

#include <QtCore/qobject.h>
#include <QtCore/qvariant.h>

#include <memory>

class QObjectProxy
{
public:
    QObjectProxy(void *owner);
    ~QObjectProxy();

    QObject *toObject() const;
    QVariant toVariant() const;

private:
    class QObjectProxyImpl;
    std::shared_ptr<QObjectProxyImpl> m_obj;
};
