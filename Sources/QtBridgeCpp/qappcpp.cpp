// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

#include "qappcpp.h"

#include <QtGui/qguiapplication.h>
#include <QtQml/qqmlapplicationengine.h>

#ifdef QT_WIDGETS_LIB
#include <QtWidgets/qapplication.h>
#endif

#ifdef QT_QUICKCONTROLS2_LIB
#include <QtQuickControls2/qquickstyle.h>
#endif

QAppCpp::QAppCpp()
{
}

QAppCpp::~QAppCpp()
{
    delete m_engine;
    delete m_app;
}

QAppCpp::QAppCpp(QAppCpp &&other) noexcept
    : m_importPaths(std::move(other.m_importPaths)),
      m_pluginsPath(std::move(other.m_pluginsPath)),
      m_map(std::move(other.m_map)),
      m_root(std::move(other.m_root)),
      m_argc(other.m_argc),
      m_argv(other.m_argv),
      m_app(other.m_app),
      m_engine(other.m_engine)
{
    other.m_app = nullptr;
    other.m_engine = nullptr;
}

QAppCpp &QAppCpp::operator=(QAppCpp &&other) noexcept
{
    if (this != &other) {
        delete m_engine;
        delete m_app;
        m_importPaths = std::move(other.m_importPaths);
        m_pluginsPath = std::move(other.m_pluginsPath);
        m_map = std::move(other.m_map);
        m_root = std::move(other.m_root);
        m_argc = other.m_argc;
        m_argv = other.m_argv;
        m_app = other.m_app;
        m_engine = other.m_engine;
        other.m_app = nullptr;
        other.m_engine = nullptr;
    }
    return *this;
}

void QAppCpp::addImportPath(const char *path)
{
    m_importPaths.push_back(QString(path));
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
    m_root = QUrl::fromLocalFile(QString::fromUtf8(path));
}

void QAppCpp::setOrganizationName(const char *name)
{
    QCoreApplication::setOrganizationName(QString::fromUtf8(name));
}

void QAppCpp::setOrganizationDomain(const char *domain)
{
    QCoreApplication::setOrganizationDomain(QString::fromUtf8(domain));
}

void QAppCpp::setApplicationName(const char *name)
{
    QCoreApplication::setApplicationName(QString::fromUtf8(name));
}

void QAppCpp::setDesktopFileName(const char *name)
{
    QGuiApplication::setDesktopFileName(QString::fromUtf8(name));
}

void QAppCpp::setStyle(const char *style)
{
#ifdef QT_QUICKCONTROLS2_LIB
    QQuickStyle::setStyle(QString::fromUtf8(style));
#endif
#ifdef QT_WIDGETS_LIB
    QApplication::setStyle(QString::fromUtf8(style));
#endif
}

void QAppCpp::createApplication(int argc, char **argv, bool useQtWidgets)
{
    m_argc = argc;
    m_argv = argv;

    if (!m_pluginsPath.isEmpty()) {
        qputenv("QT_PLUGIN_PATH", m_pluginsPath.toUtf8());
    }

#ifdef QT_WIDGETS_LIB
    if (useQtWidgets) {
        m_app = new QApplication(m_argc, m_argv);
    } else {
        m_app = new QGuiApplication(m_argc, m_argv);
    }
#else
    Q_UNUSED(useQtWidgets);
    m_app = new QGuiApplication(m_argc, m_argv);
#endif
}

void QAppCpp::createEngine()
{
    m_engine = new QQmlApplicationEngine();
}

void QAppCpp::load()
{
    if (!m_engine) return;

    for (const auto &path: m_importPaths)
        m_engine->addImportPath(path);

    m_engine->setInitialProperties(m_map);
    m_engine->load(m_root);
}

int QAppCpp::exec()
{
    if (!m_app) return -1;
    return QCoreApplication::exec();
}
