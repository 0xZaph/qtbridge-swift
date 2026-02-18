import QtBridge

@QtBridgeable
public class QmlType1 : QmlInstantiable {
    public var strProp : String = "testString"

    func updateStrProp(newStr: String) {
        strProp = newStr
    }

    required public init() {
    }
}

@QtBridgeable
public class QmlType2 : QmlInstantiable {
    public var intProp : Int = 0

    func updateIntProp(newInt: Int) {
        intProp = newInt
    }

    required public init() {
    }
}
