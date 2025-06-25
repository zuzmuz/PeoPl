extension Lsp {

    enum PositionEncoding: String, Codable {
        case utf8 = "utf-8"
        case utf16 = "utf-16"
        case utf32 = "utf-32"
    }
    struct InitializeParams: Codable {
        let processId: Int
        let capabilities: ClientCapabilities
        let clientInfo: ClientInfo?
    }

    struct ClientCapabilities: Codable {
        let workspace: WorkspaceClientCapabilities?
        let textDocument: TextDocumentClientCapabilities?
        let general: GeneralClientCapabilities?
    }

    struct ClientInfo: Codable {
        let name: String
        let version: String
    }

    struct ValueSetClientCapabilities<T: Codable>: Codable {
        let valueSet: [T]?
    }

    struct GeneralClientCapabilities: Codable {
        let positionEncodings: [PositionEncoding]?
    }

    struct WorkspaceClientCapabilities: Codable {
        let applyEdit: Bool?
        // let workspaceEdit: WorkspaceEditClientCapabilities?
        // let didChangeConfiguration: DidChangeConfigurationClientCapabilities?
        // let didChangeWatchedFiles: DidChangeWatchedFilesClientCapabilities?
        // let symbol: SymbolClientCapabilities?
        // let executeCommand: ExecuteCommandClientCapabilities?
        // let workspaceFolders: Bool?
        // let configuration: Bool?
    }

    struct TextDocumentSyncClientCapabilities: Codable {
        let dynamicRegistration: Bool?
        let willSave: Bool?
        let willSaveWaitUntil: Bool?
        let didSave: Bool?
    }

    struct TextDocumentClientCapabilities: Codable {
        let synchronization: TextDocumentSyncClientCapabilities?
        // let completion: CompletionClientCapabilities?
        // let hover: HoverClientCapabilities?
        // let signatureHelp: SignatureHelpClientCapabilities?
        // let declaration: DeclarationClientCapabilities?
        // let definition: DefinitionClientCapabilities?
        // let typeDefinition: TypeDefinitionClientCapabilities?
        // let implementation: ImplementationClientCapabilities?
        // let references: ReferenceClientCapabilities?
        // let documentHighlight: DocumentHighlightClientCapabilities?
        // let documentSymbol: DocumentSymbolClientCapabilities?
        // let codeAction: CodeActionClientCapabilities?
        // let codeLens: CodeLensClientCapabilities?
        // let documentLink: DocumentLinkClientCapabilities?
        // let colorProvider: DocumentColorClientCapabilities?
        // let formatting: DocumentFormattingClientCapabilities?
        // let rangeFormatting: DocumentRangeFormattingClientCapabilities?
        // let onTypeFormatting: DocumentOnTypeFormattingClientCapabilities?
        // let rename: RenameClientCapabilities?
        // let publishDiagnostics: PublishDiagnosticsClientCapabilities?
        // let foldingRange: FoldingRangeClientCapabilities?
        // let selectionRange: SelectionRangeClientCapabilities?
        // let linkedEditingRange: LinkedEditingRangeClientCapabilities?
        // let callHierarchy: CallHierarchyClientCapabilities?
        // let semanticTokens: SemanticTokensClientCapabilities?
        // let moniker: MonikerClientCapabilities?
        // let typeHierarchy: TypeHierarchyClientCapabilities?
        // let inlineValue: InlineValueClientCapabilities?
        // let inlayHint: InlayHintClientCapabilities?
        // let diagnostic: DiagnosticClientCapabilities?

        // TODO: Implement the rest of the capabilities

        // struct HoverClientCapabilities: Codable {}
        // struct SignatureHelpClientCapabilities: Codable {}
        // struct DeclarationClientCapabilities: Codable {}
        // struct DefinitionClientCapabilities: Codable {}
        // struct TypeDefinitionClientCapabilities: Codable {}
        // struct ImplementationClientCapabilities: Codable {}
        // struct ReferenceClientCapabilities: Codable {}
        // struct DocumentHighlightClientCapabilities: Codable {}
        // struct DocumentSymbolClientCapabilities: Codable {}
        // struct CodeActionClientCapabilities: Codable {}
        // struct CodeLensClientCapabilities: Codable {}
        // struct DocumentLinkClientCapabilities: Codable {}
        // struct DocumentColorClientCapabilities: Codable {}
        // struct DocumentFormattingClientCapabilities: Codable {}
        // struct DocumentRangeFormattingClientCapabilities: Codable {}
        // struct DocumentOnTypeFormattingClientCapabilities: Codable {}
        // struct RenameClientCapabilities: Codable {}
        // struct PublishDiagnosticsClientCapabilities: Codable {}
        // struct SelectionRangeClientCapabilities: Codable {}
        // struct LinkedEditingRangeClientCapabilities: Codable {}
        // struct CallHierarchyClientCapabilities: Codable {}
        // struct MonikerClientCapabilities: Codable {}
        // struct TypeHierarchyClientCapabilities: Codable {}
        // struct InlineValueClientCapabilities: Codable {}
        // struct InlayHintClientCapabilities: Codable {}
        // struct DiagnosticClientCapabilities: Codable {}
    }
}
