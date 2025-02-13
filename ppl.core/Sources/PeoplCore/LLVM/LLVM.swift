import cllvm


protocol LLVMBuilder {
    func llvmBuild()
}

// -lc++ -stdlib=libc++  -L/opt/homebrew/Cellar/llvm/19.1.7/lib -Wl,-search_paths_first -Wl,-headerpad_max_install_names

extension Module: LLVMBuilder {
    func llvmBuild() {
        let context = LLVMGetGlobalContext()
        let moudule = LLVMModuleCreateWithName("peoplcore")
        let builder = LLVMCreateBuilderInContext(context)
    }
}
