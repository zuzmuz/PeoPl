extension Syntax.NodeLocation: CustomDebugStringConvertible {
    var debugDescription: String {
        return "\(sourceName):\(pointRange.lowerBound.line):\(pointRange.lowerBound.column)-\(pointRange.upperBound.line):\(pointRange.upperBound.column)"
    }
}
