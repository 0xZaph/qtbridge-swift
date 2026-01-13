// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

public final class QListModel<Element: QVariantGettable>: RandomAccessCollection,
                                                          RangeReplaceableCollection,
                                                          MutableCollection,
                                                          ExpressibleByArrayLiteral {
    private var storage: [Element]
    private let model: QAbstractListModel

    public init() {
        self.storage = []
        self.model = QAbstractListModel()
        self.model.bind(owner: self, keyPath: \.storage)
    }

    public convenience init<S: Sequence>(_ elements: S)
    where S.Element == Element {
        self.init()
        self.storage = Array(elements)
    }

    public convenience init(arrayLiteral elements: Element...) {
        self.init(elements)
    }

    public var startIndex: Int { storage.startIndex }
    public var endIndex: Int   { storage.endIndex }
    public func index(after i: Int) -> Int { storage.index(after: i) }

    public subscript(position: Int) -> Element {
        get { storage[position] }
        set {
            precondition(position >= 0 && position < storage.count, "Index out of range")
            storage[position] = newValue
            model.emitDataChanged(Int32(position), Int32(position), [])
        }
    }

    public func replaceSubrange<C: Collection>(_ subrange: Range<Int>, with newElements: C)
    where C.Element == Element {
        let oldCount = subrange.count
        let newCount = newElements.count

        if oldCount == 0 && newCount == 0 { return }
        let first = Int32(subrange.lowerBound)

        switch (oldCount, newCount) {
        // Insert
        case (0, let newItems) where newItems > 0:
            let last = Int32(subrange.lowerBound + newItems - 1)
            model.beginInsertRows(QModelIndex(), first, last)
            storage.replaceSubrange(subrange, with: newElements)
            model.endInsertRows()
        // Remove
        case (let oldItems, 0) where oldItems > 0:
            let last = Int32(subrange.upperBound - 1)
            model.beginRemoveRows(QModelIndex(), first, last)
            storage.replaceSubrange(subrange, with: newElements)
            model.endRemoveRows()
        // Replace
        default:
            if oldCount > 0 {
                let lastRem = Int32(subrange.upperBound - 1)
                model.beginRemoveRows(QModelIndex(), first, lastRem)
                storage.removeSubrange(subrange)
                model.endRemoveRows()
            }
            if newCount > 0 {
                let lastIns = Int32(subrange.lowerBound + newCount - 1)
                model.beginInsertRows(QModelIndex(), first, lastIns)
                storage.insert(contentsOf: newElements, at: subrange.lowerBound)
                model.endInsertRows()
            }
        }
    }

    public func reset(to newElements: [Element] = []) {
        model.beginResetModel()
        storage = newElements
        model.endResetModel()
    }

    public var asArray: [Element] { storage }
}

extension QListModel: QVariantGettable {
    public func toVariant() -> QVariant {
        return QVariant(model: self.model)
    }
    public static func metaType() -> Int32 {
        return 39
    }
}
