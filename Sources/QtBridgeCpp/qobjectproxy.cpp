// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

#include "qobjectproxy.h"

#include "swiftobjectaccesor.h"

// QObjectProxyImpl

class QObjectProxy::QObjectProxyImpl : public QObject,
                                       public SwiftObjectAccesor
{
public:
    QObjectProxyImpl(void * owner)
        : m_owner(owner)
    {
    }

    // SwiftObjectAccessor
    void* swiftObject() const
    {
        return m_owner;
    }

private:
    void *m_owner;
};

QObjectProxy::QObjectProxy(void *owner)
{
    m_obj = std::make_shared<QObjectProxyImpl>(owner);
}

QObjectProxy::~QObjectProxy()
{
}

QObject * QObjectProxy::toObject() const
{
    return m_obj.get();
}

QVariant QObjectProxy::toVariant() const
{
    return QVariant::fromValue(m_obj.get());
}
