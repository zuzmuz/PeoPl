extension Lsp {
    public struct DocumentDiagnosticParams {
        let textDocument: TextDocumentIdentifier
        let identifier: String?
        let previousResultId: String?
    }

    public enum DocumentDiagnosticReportKind: Codable {
        case full
        case unchanged
    }

    public struct FullDocumentDiagnosticReport: Codable {
        let kind: DocumentDiagnosticReportKind = .full
        let resultId: String?
        let items: [Diagnostic]
    }

    public struct UnchangedDocumentDiagnosticReport: Codable {
        let kind: DocumentDiagnosticReportKind = .unchanged
        let resultId: String
    }

    public struct RelatedFullDocumentDiagnosticReport: Codable {
        let full: FullDocumentDiagnosticReport
        let relatedDocuments: [String: FullDocumentDiagnosticReport]

    public struct Diagnostic: Codable {
        // let range: Range
        // let severity: DiagnosticSeverity?
        // let code: String?
        // let source: String?
        // let message: String
        // let relatedInformation: [DiagnosticRelatedInformation]?
    }

    public struct DocumentDiagnosticReport {
    }
}
