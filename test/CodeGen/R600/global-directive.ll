; RUN: llc -march=r600 -mcpu=SI -verify-machineinstrs < %s | FileCheck -check-prefix=SI %s

; Make sure the GlobalDirective isn't merged with the function name

; SI:	.globl	foo
; SI: {{^}}foo:
define void @foo(i32 addrspace(1)* %out, i32 addrspace(1)* %in) {
  %b_ptr = getelementptr i32 addrspace(1)* %in, i32 1
  %a = load i32 addrspace(1)* %in
  %b = load i32 addrspace(1)* %b_ptr
  %result = add i32 %a, %b
  store i32 %result, i32 addrspace(1)* %out
  ret void
}
