; RUN: llc -mtriple=x86_64-linux -O0 -o - -filetype=obj < %s | llvm-dwarfdump -debug-dump=info -| FileCheck %s
; RUN: llc -mtriple=x86_64-linux -dwarf-version=2 -O0 -o - -filetype=obj < %s | llvm-dwarfdump -debug-dump=info -| FileCheck -check-prefix=DWARF2 %s

; Generated from Clang with the following source:
;
; struct foo {
;   char c;
;   int i;
; };
; 
; foo f;

; CHECK: DW_AT_name {{.*}} "c"
; CHECK-NOT: DW_TAG
; CHECK: DW_AT_data_member_location {{.*}} (0x00)

; CHECK: DW_AT_name {{.*}} "i"
; CHECK-NOT: DW_TAG
; CHECK: DW_AT_data_member_location {{.*}} (0x04)

; DWARF2: DW_AT_name {{.*}} "c"
; DWARF2-NOT: DW_TAG
; DWARF2: DW_AT_data_member_location {{.*}} (<0x02> 23 00 )

; DWARF2: DW_AT_name {{.*}} "i"
; DWARF2-NOT: DW_TAG
; DWARF2: DW_AT_data_member_location {{.*}} (<0x02> 23 04 )

%struct.foo = type { i8, i32 }

@f = global %struct.foo zeroinitializer, align 4

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!13, !15}
!llvm.ident = !{!14}

!0 = metadata !{metadata !"0x11\004\00clang version 3.4 \000\00\000\00\000", metadata !1, metadata !2, metadata !3, metadata !2, metadata !10, metadata !2} ; [ DW_TAG_compile_unit ] [/tmp/dbginfo/data_member_location.cpp] [DW_LANG_C_plus_plus]
!1 = metadata !{metadata !"data_member_location.cpp", metadata !"/tmp/dbginfo"}
!2 = metadata !{}
!3 = metadata !{metadata !4}
!4 = metadata !{metadata !"0x13\00foo\001\0064\0032\000\000\000", metadata !1, null, null, metadata !5, null, null, metadata !"_ZTS3foo"} ; [ DW_TAG_structure_type ] [foo] [line 1, size 64, align 32, offset 0] [def] [from ]
!5 = metadata !{metadata !6, metadata !8}
!6 = metadata !{metadata !"0xd\00c\002\008\008\000\000", metadata !1, metadata !"_ZTS3foo", metadata !7} ; [ DW_TAG_member ] [c] [line 2, size 8, align 8, offset 0] [from char]
!7 = metadata !{metadata !"0x24\00char\000\008\008\000\000\006", null, null} ; [ DW_TAG_base_type ] [char] [line 0, size 8, align 8, offset 0, enc DW_ATE_signed_char]
!8 = metadata !{metadata !"0xd\00i\003\0032\0032\0032\000", metadata !1, metadata !"_ZTS3foo", metadata !9} ; [ DW_TAG_member ] [i] [line 3, size 32, align 32, offset 32] [from int]
!9 = metadata !{metadata !"0x24\00int\000\0032\0032\000\000\005", null, null} ; [ DW_TAG_base_type ] [int] [line 0, size 32, align 32, offset 0, enc DW_ATE_signed]
!10 = metadata !{metadata !11}
!11 = metadata !{metadata !"0x34\00f\00f\00\006\000\001", null, metadata !12, metadata !4, %struct.foo* @f, null} ; [ DW_TAG_variable ] [f] [line 6] [def]
!12 = metadata !{metadata !"0x29", metadata !1}         ; [ DW_TAG_file_type ] [/tmp/dbginfo/data_member_location.cpp]
!13 = metadata !{i32 2, metadata !"Dwarf Version", i32 4}
!14 = metadata !{metadata !"clang version 3.4 "}

!15 = metadata !{i32 1, metadata !"Debug Info Version", i32 2}
