import Foundation

enum SourceManager {
	static func readCurrentDirectory() throws -> Syntax.Project {
		let fileManager = FileManager.default
		let currentDirectory = URL(
			filePath: fileManager.currentDirectoryPath
		)

		let contents = try fileManager.contentsOfDirectory(
			at: currentDirectory,
			includingPropertiesForKeys: [.isRegularFileKey],
			options: [.skipsHiddenFiles]
		)

		let modules: [String: Syntax.Module] =
			try contents.reduce(into: [:]) { acc, url in
				guard url.pathExtension == "ppl" else { return }
				let source = try Syntax.Source(url: url)
				acc[url.absoluteString] =
					TreeSitterModulParser.parseModule(source: source)
			}

		return .init(modules: modules)
	}

	static func readSingleFile(path: String) throws -> Syntax.Project {
		let source = try Syntax.Source(path: path)
		let module = TreeSitterModulParser.parseModule(source: source)
		return .init(modules: [path: module])
	}
}
