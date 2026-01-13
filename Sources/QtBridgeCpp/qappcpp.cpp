// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

#include "qappcpp.h"

#include <QtGui/qguiapplication.h>
#include <QtQml/qqmlapplicationengine.h>

QAppCpp::QAppCpp()
{
}

QAppCpp::~QAppCpp()
{
}

void QAppCpp::setImportPath(const char *path)
{
    m_importPath = QString(path);
}

void QAppCpp::setPluginsPath(const char *path)
{
    m_pluginsPath = QString(path);
}

void QAppCpp::addInitialProperty(const char *name, QVariant value)
{
    m_map.insert(QString::fromUtf8(name), value);
}

void QAppCpp::setRootQml(const char *path)
{
    m_root = QUrl(QString::fromUtf8(path));
}

int QAppCpp::run(int argc, char **argv)
{
    qputenv("QT_PLUGIN_PATH", m_pluginsPath.toUtf8());

    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    engine.addImportPath(m_importPath);

    engine.setInitialProperties(m_map);
    engine.load(m_root);

    return app.exec();
}
