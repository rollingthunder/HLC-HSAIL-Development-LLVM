; RUN: llc -march=hsail < %s | FileCheck -check-prefix=HSAIL %s

; FIXME: Should also support i64

declare i32 @llvm.HSAIL.firstbit.u32(i32) #0

; HSAIL-LABEL: {{^}}prog function &test_firstbit_f32(
; HSAIL: firstbit_u32_u32 {{\$s[0-9]+}}, {{\$s[0-9]+}};
define i32 @test_firstbit_f32(i32 %x) #0 {
  %cos = call i32 @llvm.HSAIL.firstbit.u32(i32 %x) #0
  ret i32 %cos
}

attributes #0 = { nounwind readnone }
