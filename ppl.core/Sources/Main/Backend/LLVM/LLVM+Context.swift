extension Semantic.DefinitionsContext {
	func llvmBuild(
		llvm: inout LLVM.Builder
	) throws(LLVM.Error) {
		try llvmBuildTypes(llvm: &llvm)
		try llvmBuildFunctions(llvm: &llvm)
	}
}
