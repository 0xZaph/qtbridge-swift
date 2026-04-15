// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only

import QtBridgeCpp

@MainActor
public class QMetaParamsList {
    private let args: MetaParamsList

    internal init(args: MetaParamsList) {
        self.args = args
    }

    public func get<T: QMetaParamsGettable>(_ index: Int) -> T {
        return T.get(from: self, index: index)
    }

    fileprivate func getBool(_ index: Int) -> Bool { return args.getBool(index) }
    fileprivate func getInt(_ index: Int) -> Int { return Int(args.getInt(index)) }
    fileprivate func getUInt(_ index: Int) -> UInt { return UInt(args.getUInt(index)) }
    fileprivate func getDouble(_ index: Int) -> Double { return args.getDouble(index) }
    fileprivate func getFloat(_ index: Int) -> Float { return args.getFloat(index) }
    fileprivate func getString(_ index: Int) -> String { return String(args.getString(index)) }
    fileprivate func getStringList(_ index: Int) -> [String] {
        var result : [String] = []
        let list = args.getStringList(index)
        for i in 0..<list.size() {
            result.append(list[i].toSwiftString())
        }
        return result
    }
    fileprivate func getMap(_ index: Int) -> [String: QVariantSettable] {
        return args.getVariantMap(index).toBridgeMap()
    }
}

@MainActor
public protocol QMetaParamsGettable {
    static func get(from params: QMetaParamsList, index: Int) -> Self
}

extension Bool: QMetaParamsGettable {
    public static func get(from params: QMetaParamsList, index: Int) -> Bool {
        return params.getBool(index)
    }
}

extension Int: QMetaParamsGettable {
    public static func get(from params: QMetaParamsList, index: Int) -> Int {
        return params.getInt(index)
    }
}

extension UInt: QMetaParamsGettable {
    public static func get(from params: QMetaParamsList, index: Int) -> UInt {
        return params.getUInt(index)
    }
}

extension Double: QMetaParamsGettable {
    public static func get(from params: QMetaParamsList, index: Int) -> Double {
        return params.getDouble(index)
    }
}

extension Float: QMetaParamsGettable {
    public static func get(from params: QMetaParamsList, index: Int) -> Float {
        return params.getFloat(index)
    }
}

extension String: QMetaParamsGettable {
    public static func get(from params: QMetaParamsList, index: Int) -> String {
        return params.getString(index)
    }
}

extension Array: QMetaParamsGettable where Element == String {
    public static func get(from params: QMetaParamsList, index: Int) -> [String] {
        return params.getStringList(index)
    }
}

extension Dictionary: QMetaParamsGettable where Key == String, Value == any QVariantSettable {
    public static func get(from params: QMetaParamsList, index: Int) -> [String: QVariantSettable] {
        return params.getMap(index)
    }
}
