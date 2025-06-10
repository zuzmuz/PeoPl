import Foundation

do {
    // let module = try Syntax.Module(
    //   path: "/Users/zuz/Desktop/Muz/coding/peopl/examples/main.ppl")
    let folderPath =
        "/Users/zuz/Desktop/Muz/coding/peopl/ppl.core/Tests/testreferences/"
    print("folderPath: \(folderPath)")

    let folder = try FileManager.default.contentsOfDirectory(atPath: folderPath)
    let decoder = JSONDecoder()

    let files = folder.compactMap { fileName in
        print("fileName: \(fileName)")
        if fileName.hasSuffix(".json") {
            let handle = FileHandle(forReadingAtPath: folderPath + fileName)
            guard let outputData = try? handle?.readToEnd() else {
                fatalError("unable to read file \(fileName)")
            }
            print("Data \(String(data: outputData, encoding: .utf8) ?? "nil")")
            do {
                let module = try decoder.decode(
                    Syntax.Module.self, from: outputData)
                return module
            } catch {
                print("handling error: \(error)")
            }
            return nil
        }
        return nil
    }

    print(files.first?.definitions.count)
} catch {
    print("we catching \(error.localizedDescription)")
}
