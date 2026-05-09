// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#pragma once

#include <QtCore/qobject.h>
#include <QtCore/qurl.h>
#include <QtCore/qvariant.h>

#include <swift/bridging>

#include "qobjectproxy.h"

class QCoreApplication;
class QQmlApplicationEngine;

class QAppCpp {
public:
  QAppCpp();
  ~QAppCpp();

  QAppCpp(const QAppCpp &) = delete;
  QAppCpp &operator=(const QAppCpp &) = delete;

  QAppCpp(QAppCpp &&other) noexcept;
  QAppCpp &operator=(QAppCpp &&other) noexcept;

  void addImportPath(const char *path);
  void setPluginsPath(const char *path);

  void addInitialProperty(const char *name, QVariant value);
  void setRootQml(const char *path);

  static void setOrganizationName(const char *name);
  static void setOrganizationDomain(const char *domain);
  static void setApplicationName(const char *name);
  static void setDesktopFileName(const char *name);
  static void setStyle(const char *style);

  void createApplication(int argc, char **argv, bool useQtWidgets);
  void createEngine();
  void load();
  int exec();

  void *getAppPointer() const { return m_app; }
  void *getEnginePointer() const SWIFT_RETURNS_INDEPENDENT_VALUE {
    return m_engine;
  }

private:
  std::vector<QString> m_importPaths;
  QString m_pluginsPath;
  QVariantMap m_map;
  QUrl m_root;

  int m_argc = 0;
  char **m_argv = nullptr;

  QCoreApplication *m_app = nullptr;
  QQmlApplicationEngine *m_engine = nullptr;
};
