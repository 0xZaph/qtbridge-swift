// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

#include "metaparamslist.h"

#include <QtCore/qstring.h>

MetaParamsList::MetaParamsList(
    const QMetaMethod &method, void **paramData)
    : m_method(method),
      m_paramData(paramData)
{
}

int MetaParamsList::size() const
{
    return m_method.parameterCount();
}

bool MetaParamsList::getBool(size_t i) const { return getT<bool>(i); }

int64_t MetaParamsList::getInt(size_t i) const { return getT<int64_t>(i); }

uint64_t MetaParamsList::getUInt(size_t i) const { return getT<uint64_t>(i); }

float MetaParamsList::getFloat(size_t i) const { return getT<float>(i); }

double MetaParamsList::getDouble(size_t i) const { return getT<double>(i); }

std::string MetaParamsList::getString(size_t i) const
{
    return getT<QString>(i).toStdString();
}

std::vector<std::string> MetaParamsList::getStringList(size_t i) const {
    const auto list = getT<QStringList>(i);
    std::vector<std::string> result;
    result.reserve(list.size());
    for (const QString& qstr : list)
        result.push_back(qstr.toStdString());
    return result;
}
