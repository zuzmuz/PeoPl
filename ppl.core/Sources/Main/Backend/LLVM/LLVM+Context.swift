extension Semantic.DefinitionsContext {
    func llvmBuild(
        llvm: inout LLVM.Builder
    ) throws(LLVM.Error) {
        try self.llvmBuildTypes(llvm: &llvm)
        try self.llvmBuildFunctions(llvm: &llvm)
    }
}
