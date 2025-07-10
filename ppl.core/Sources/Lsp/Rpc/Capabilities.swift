extension Lsp {

    public enum PositionEncoding: String, Codable, Sendable {
        case utf8 = "utf-8"
        case utf16 = "utf-16"
        case utf32 = "utf-32"
    }

    public struct InitializeParams: Codable, Sendable {
        public let processId: Int
        public let capabilities: ClientCapabilities
        public let clientInfo: ClientInfo?
        public let workspaceFolders: [WorkspaceFolder]?
        public let locale: String?
    }

    public struct WorkspaceFolder: Codable, Sendable {
        public let uri: String
        public let name: String
    }

    public struct ClientCapabilities: Codable, Sendable {
        public let workspace: WorkspaceClientCapabilities?
        public let textDocument: TextDocumentClientCapabilities?
        public let general: GeneralClientCapabilities?
    }

    public struct ClientInfo: Codable, Sendable {
        public let name: String
        public let version: String
    }

    public struct ValueSetClientCapabilities<T: Codable>: Codable {
        public let valueSet: [T]?
    }

    public struct GeneralClientCapabilities: Codable, Sendable {
        public let positionEncodings: [PositionEncoding]?
    }

    public struct WorkspaceClientCapabilities: Codable, Sendable {
        public let applyEdit: Bool?
        // let workspaceEdit: WorkspaceEditClientCapabilities?
        // let didChangeConfiguration: DidChangeConfigurationClientCapabilities?
        // let didChangeWatchedFiles: DidChangeWatchedFilesClientCapabilities?
        // let symbol: SymbolClientCapabilities?
        // let executeCommand: ExecuteCommandClientCapabilities?
        // let workspaceFolders: Bool?
        // let configuration: Bool?
    }

    public struct TextDocumentSyncClientCapabilities: Codable, Sendable {
        public let dynamicRegistration: Bool?
        public let willSave: Bool?
        public let willSaveWaitUntil: Bool?
        public let didSave: Bool?
    }

    public struct TextDocumentClientCapabilities: Codable, Sendable {
        public let synchronization: TextDocumentSyncClientCapabilities?
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

    public struct InitializeResult: Codable, Sendable {
        public let capabilities: ServerCapabilities
        public let serverInfo: ServerInfo?

        public init(
            capabilities: ServerCapabilities,
            serverInfo: ServerInfo?
        ) {
            self.capabilities = capabilities
            self.serverInfo = serverInfo
        }
    }

    public struct ServerCapabilities: Codable, Sendable {

        public enum TextDocumentSync: Int, Codable, Sendable {
            /// Documents are not synced
            case none = 0
            /// Documents are synced by always sending the full content
            case full = 1
            /// Documents are synced by sending the full content on open. After that only incremental updates to the document are sent
            case incremental = 2
        }

        public struct CompletionProvider: Codable, Sendable {
            let triggerCharacters: [String]
            let resolveProvider: Bool
        }

        public struct DiagnosticOptions: Codable, Sendable {
            public let interFileDependencies: Bool
            public let workspaceDiagnostics: Bool

            public init(
                interFileDependencies: Bool,
                workspaceDiagnostics: Bool
            ) {
                self.interFileDependencies = interFileDependencies
                self.workspaceDiagnostics = workspaceDiagnostics
            }
        }

        let positionEncoding: PositionEncoding?
        let textDocumentSync: TextDocumentSync?
        let diagnosticProvider: DiagnosticOptions?
        // let completionProvider: CompletionProvider?
        // let foldingRangeProvider: Bool?
        // let semanticTokensProvider: SemanticTokensOptions?

        public init(
            positionEncoding: PositionEncoding? = nil,
            textDocumentSync: TextDocumentSync? = nil,
            diagnosticProvider: DiagnosticOptions? = nil,
        ) {
            self.positionEncoding = positionEncoding
            self.textDocumentSync = textDocumentSync
            self.diagnosticProvider = diagnosticProvider
        }
    }

    public struct ServerInfo: Codable, Sendable {
        public let name: String
        public let version: String?

        public init(name: String, version: String?) {
            self.name = name
            self.version = version
        }
    }
}
