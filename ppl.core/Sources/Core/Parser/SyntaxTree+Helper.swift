extension Syntax.NodeLocation: CustomDebugStringConvertible {
    public var debugDescription: String {
        return
            "\(pointRange.lowerBound.line):\(pointRange.lowerBound.column)-\(pointRange.upperBound.line):\(pointRange.upperBound.column)"
    }
}
