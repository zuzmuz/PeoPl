import cllvm
import llvmwrapper


protocol LLVMBuilder {
    func llvmBuild()
}


extension Module: LLVMBuilder {
    func llvmBuild() {
        let h = LLVMGetGlobalContext()
        print(function2())
    }
}
