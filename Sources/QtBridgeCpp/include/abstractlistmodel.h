// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#pragma once

#include "callbackbase.h"

#include <QtCore/qabstractitemmodel.h>

#include <memory>

#include <swift/bridging>

class QAbstractListModelCpp
{
public:
    explicit QAbstractListModelCpp(void* swiftModel);
    ~QAbstractListModelCpp();

    QAbstractListModelCpp(const QAbstractListModelCpp&) = delete;
    QAbstractListModelCpp& operator=(const QAbstractListModelCpp&) = delete;
    QAbstractListModelCpp(QAbstractListModelCpp&&) = delete;
    QAbstractListModelCpp& operator=(QAbstractListModelCpp&&) = delete;

    static QAbstractListModelCpp* create(void* swiftModel) {
        return new QAbstractListModelCpp(swiftModel);
    }

    static void destroy(QAbstractListModelCpp* ptr) {
        delete ptr;
    }

    QAbstractListModel* getModel() const;
    QVariant toVariant() const;

    static void registerRowCount(CallbackBase::RowCountFunc rowCountCallback);
    static void registerData(CallbackBase::DataFunc dataCallback);
    static void registerSetData(CallbackBase::SetDataFunc setDataCallback);
    static void registerRoleNames(CallbackBase::RoleNamesFunc roleNamesCallback);

    void beginInsertRows(const QModelIndex parent, int first, int last);
    void endInsertRows();

    void beginRemoveRows(const QModelIndex &parent, int first, int last);
    void endRemoveRows();

    void beginResetModel();
    void endResetModel();

    void emitDataChanged(int topLeft, int bottomRight, const int *roles = nullptr, int roleCount = 0);

private:
    void *m_swiftModel;
    class QAbstractListModelImpl;
    std::unique_ptr<QAbstractListModelImpl> m_impl;

    inline static CallbackBase::RowCountFunc s_rowCountFunc = nullptr;
    inline static CallbackBase::DataFunc s_dataFunc = nullptr;
    inline static CallbackBase::SetDataFunc s_setDataFunc = nullptr;
    inline static CallbackBase::RoleNamesFunc s_roleNamesFunc = nullptr;
} SWIFT_IMMORTAL_REFERENCE;
