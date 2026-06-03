import QtBridge

@MainActor
public class Modelle {
    var name: String
    var value: Int

    public init(_ name: String, _ value: Int) {
        self.name = name
        self.value = value
    }
}


#if canImport(QtBridge)
public typealias ModelleList = [Modelle]
#else
public typealias ModelleList = [Modelle]
#endif


@MainActor
public class Modellette {
#if canImport(QtBridge)
    public var modelles: ModelleList = [Modelle("one", 1), Modelle("two", 2)]
#endif


private var _objectHolder: QtBridge.QObjectHolder?

public lazy var objectHolder: QtBridge.QObjectHolder = {
    if let object = _objectHolder {
        return object
    }
    return QtBridge.QObjectHolder(owner: self)
}()

static public let metaObjectBuilder: QtBridge.QMetaObjectBuilder = {
    return QtBridge.QMetaObjectBuilder.create(from: Modellette.self)
}()

public static func registerMethodsAndProperties(for builder: QtBridge.QMetaObjectBuilder) {
    builder.startRegistration(for: self)

}

public static func registerMetaTypeInterface(for builder: QtBridge.QMetaObjectBuilder) {
    builder.registerCreateFn(objectHolderPath: \Modellette._objectHolder)
}
}

extension Modellette: QtBridge.QObjectBuildable {
}
