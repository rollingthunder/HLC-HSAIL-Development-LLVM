; RUN: llc -march=hsail -verify-machineinstrs < %s | FileCheck -check-prefix=HSAIL -check-prefix=FUNC %s

; HSAIL-DAG: readonly_f32 &float_gv[5] = {0F00000000, 0F3f800000, 0F40000000, 0F40400000, 0F40800000};
; HSAIL-DAG: readonly_f64 &double_gv[5] = {0D0000000000000000, 0D3ff0000000000000, 0D4000000000000000, 0D4008000000000000, 0D4010000000000000};
; HSAIL-DAG: readonly_u32 &i32_gv[5] = {0, 1, 2, 3, 4};
; HSAIL-DAG: align(8) readonly_u8 &struct_foo_gv[24] = {0, 0, 128, 65, 0, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 4, 0, 0, 0};
; HSAIL-DAG: readonly_u32 &array_v1_gv[4] = {1, 2, 3, 4};
; HSAIL-DAG: align(8) readonly_u8 &struct_foo_zeroinit[240] = {0};
; HSAIL-DAG: align(8) readonly_u8 &bare_struct_foo_zeroinit[24] = {0};

;HSAIL-DAG: align(8) readonly_u8 &struct_foo_partial_zeroinit[48] = {0, 0, 128, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

; HSAIL-DAG: readonly_u32 &zeroinit_scalar_array[1025] = {0};
; HSAIL-DAG: align(16) readonly_u32 &zeroinit_vector_array[16] = {0};

@b = internal addrspace(2) constant [1 x i16] [ i16 7 ], align 2

@float_gv = internal unnamed_addr addrspace(2) constant [5 x float] [float 0.0, float 1.0, float 2.0, float 3.0, float 4.0], align 4
@double_gv = internal unnamed_addr addrspace(2) constant [5 x double] [double 0.0, double 1.0, double 2.0, double 3.0, double 4.0], align 4

%struct.foo = type { float, [5 x i32] }

@struct_foo_gv = internal unnamed_addr addrspace(2) constant [1 x %struct.foo] [ %struct.foo { float 16.0, [5 x i32] [i32 0, i32 1, i32 2, i32 3, i32 4] } ]

@struct_foo_zeroinit = internal unnamed_addr addrspace(2) constant [10 x %struct.foo] zeroinitializer

@bare_struct_foo_zeroinit = internal unnamed_addr addrspace(2) constant %struct.foo zeroinitializer

@struct_foo_partial_zeroinit = internal unnamed_addr addrspace(2) constant [2 x %struct.foo] [
  %struct.foo { float 1.0, [5 x i32] zeroinitializer },
  %struct.foo { float 2.0, [5 x i32] zeroinitializer }
]

@zeroinit_scalar_array = internal unnamed_addr addrspace(2) constant [1025 x i32] zeroinitializer
@zeroinit_vector_array = internal addrspace(2) constant [4 x <4 x i32>] zeroinitializer

@array_v1_gv = internal addrspace(2) constant [4 x <1 x i32>] [ <1 x i32> <i32 1>,
                                                                <1 x i32> <i32 2>,
                                                                <1 x i32> <i32 3>,
                                                                <1 x i32> <i32 4> ]

; FUNC-LABEL: @float
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_f32 [[LD:\$s[0-9]+]], [&float_gv]{{\[}}[[ADDR]]{{\]}};
; HSAIL: st_global_align(4)_f32 [[LD]]
; HSAIL: ret;
define void @float(float addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [5 x float] addrspace(2)* @float_gv, i32 0, i32 %index
  %tmp1 = load float addrspace(2)* %tmp0
  store float %tmp1, float addrspace(1)* %out
  ret void
}


; FUNC-LABEL: @double
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 3;
; HSAIL: ld_readonly_align(8)_f64 [[LD:\$d[0-9]+]], [&double_gv]{{\[}}[[ADDR]]{{\]}};
; HSAIL: st_global_align(8)_f64 [[LD]]
; HSAIL: ret;
define void @double(double addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [5 x double] addrspace(2)* @double_gv, i32 0, i32 %index
  %tmp1 = load double addrspace(2)* %tmp0
  store double %tmp1, double addrspace(1)* %out
  ret void
}

@i32_gv = internal unnamed_addr addrspace(2) constant [5 x i32] [i32 0, i32 1, i32 2, i32 3, i32 4], align 4

; FUNC-LABEL: @i32
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_u32 [[LD:\$s[0-9]+]], [&i32_gv]{{\[}}[[ADDR]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @i32(i32 addrspace(1)* %out, i32 %index) {
  %tmp0 = getelementptr inbounds [5 x i32] addrspace(2)* @i32_gv, i32 0, i32 %index
  %tmp1 = load i32 addrspace(2)* %tmp0
  store i32 %tmp1, i32 addrspace(1)* %out
  ret void
}

; FUNC-LABEL: @struct_foo_gv_load
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_u32 [[LD:\$s[0-9]+]], [&struct_foo_gv]{{\[}}[[ADDR]]+4{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @struct_foo_gv_load(i32 addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds [1 x %struct.foo] addrspace(2)* @struct_foo_gv, i32 0, i32 0, i32 1, i32 %index
  %load = load i32 addrspace(2)* %gep, align 4
  store i32 %load, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: @struct_foo_gv_zeroinit_load
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_u32 [[LD:\$s[0-9]+]], [&struct_foo_zeroinit]{{\[}}[[ADDR]]+4{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @struct_foo_gv_zeroinit_load(i32 addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds [10 x %struct.foo] addrspace(2)* @struct_foo_zeroinit, i32 0, i32 0, i32 1, i32 %index
  %load = load volatile i32 addrspace(2)* %gep, align 4
  store i32 %load, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: @bare_struct_foo_gv_zeroinit_load
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_u32 [[LD:\$s[0-9]+]], [&bare_struct_foo_zeroinit]{{\[}}[[ADDR]]+4{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @bare_struct_foo_gv_zeroinit_load(i32 addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds %struct.foo addrspace(2)* @bare_struct_foo_zeroinit, i32 0, i32 1, i32 %index
  %load = load volatile i32 addrspace(2)* %gep, align 4
  store i32 %load, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: @struct_foo_gv_partial_zeroinit_load
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_u32 [[LD:\$s[0-9]+]], [&struct_foo_partial_zeroinit]{{\[}}[[ADDR]]+4{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @struct_foo_gv_partial_zeroinit_load(i32 addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds [2 x %struct.foo] addrspace(2)* @struct_foo_partial_zeroinit, i32 0, i32 0, i32 1, i32 %index
  %load = load volatile i32 addrspace(2)* %gep, align 4
  store i32 %load, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: @array_v1_gv_load
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_u32 [[LD:\$s[0-9]+]], [&array_v1_gv]{{\[}}[[ADDR]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @array_v1_gv_load(<1 x i32> addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds [4 x <1 x i32>] addrspace(2)* @array_v1_gv, i32 0, i32 %index
  %load = load <1 x i32> addrspace(2)* %gep, align 4
  store <1 x i32> %load, <1 x i32> addrspace(1)* %out, align 4
  ret void
}


; FUNC-LABEL: @zeroinit_scalar_array_load
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_u32 [[LD:\$s[0-9]+]], [&zeroinit_scalar_array]{{\[}}[[ADDR]]{{\]}};
; HSAIL: st_global_align(4)_u32 [[LD]]
; HSAIL: ret;
define void @zeroinit_scalar_array_load(i32 addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds [1025 x i32] addrspace(2)* @zeroinit_scalar_array, i32 0, i32 %index
  %load = load i32 addrspace(2)* %gep, align 4
  store i32 %load, i32 addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: @zeroinit_vector_array_load
define void @zeroinit_vector_array_load(<4 x i32> addrspace(1)* %out, i32 %index) {
  %gep = getelementptr inbounds [4 x <4 x i32>] addrspace(2)* @zeroinit_vector_array, i32 0, i32 %index
  %load = load <4 x i32> addrspace(2)* %gep, align 16
  store <4 x i32> %load, <4 x i32> addrspace(1)* %out, align 16
  ret void
}

; FUNC-LABEL: @gv_addressing_in_branch
; HSAIL: shl_u32 [[ADDR:\$s[0-9]+]], {{\$s[0-9]+}}, 2;
; HSAIL: ld_readonly_align(4)_f32 [[LD:\$s[0-9]+]], [&float_gv]{{\[}}[[ADDR]]{{\]}};
; HSAIL: st_global_align(4)_f32 [[LD]]
; HSAIL: ret;
define void @gv_addressing_in_branch(float addrspace(1)* %out, i32 %index, i32 %a) {
entry:
  %tmp0 = icmp eq i32 0, %a
  br i1 %tmp0, label %if, label %else

if:
  %tmp1 = getelementptr inbounds [5 x float] addrspace(2)* @float_gv, i32 0, i32 %index
  %tmp2 = load float addrspace(2)* %tmp1
  store float %tmp2, float addrspace(1)* %out
  br label %endif

else:
  store float 1.0, float addrspace(1)* %out
  br label %endif

endif:
  ret void
}