//===- HSAILSelectionDAGInfo.h - HSAIL SelectionDAG Info --------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the HSAIL subclass for TargetSelectionDAGInfo.
//
//===----------------------------------------------------------------------===//

#ifndef _HSAIL_SELECTION_DAG_INFO_H_
#define _HSAIL_SELECTION_DAG_INFO_H_

#include "llvm/Target/TargetSelectionDAGInfo.h"

namespace llvm {

class HSAILTargetLowering;
class HSAILTargetMachine;
class HSAILSubtarget;

class HSAILSelectionDAGInfo : public TargetSelectionDAGInfo {
  /// Subtarget - Keep a pointer to the HSAILSubtarget around so that we can
  /// make the right decision when generating code for different targets.
  const HSAILSubtarget *Subtarget;

  const HSAILTargetLowering &TLI;

public:
  explicit HSAILSelectionDAGInfo(const HSAILTargetMachine &TM);
  ~HSAILSelectionDAGInfo();

   /// EmitTargetCodeForMemcpy - Emit target-specific code that performs a
  /// memcpy. This can be used by targets to provide code sequences for cases
  /// that don't fit the target's parameters for simple loads/stores and can be
  /// more efficient than using a library call. This function can return a null
  /// SDValue if the target declines to use custom code and a different
  /// lowering strategy should be used.
  ///
  /// If AlwaysInline is true, the size is constant and the target should not
  /// emit any calls and is strongly encouraged to attempt to emit inline code
  /// even if it is beyond the usual threshold because this intrinsic is being
  /// expanded in a place where calls are not feasible (e.g. within the prologue
  /// for another call). If the target chooses to decline an AlwaysInline
  /// request here, legalize will resort to using simple loads and stores.
  virtual SDValue
  EmitTargetCodeForMemcpy(SelectionDAG &DAG,
                          DebugLoc dl,
                          SDValue Chain,
                          SDValue Op1,
                          SDValue Op2,
                          SDValue Op3,
                          unsigned Align,
                          bool isVolatile,
                          bool AlwaysInline,
                          MachinePointerInfo DstPtrInfo,
                          MachinePointerInfo SrcPtrInfo) const;

  /// EmitTargetCodeForMemmove - Emit target-specific code that performs a
  /// memmove. This can be used by targets to provide code sequences for cases
  /// that don't fit the target's parameters for simple loads/stores and can be
  /// more efficient than using a library call. This function can return a null
  /// SDValue if the target declines to use custom code and a different
  /// lowering strategy should be used.
  virtual SDValue
  EmitTargetCodeForMemmove(SelectionDAG &DAG,
                           DebugLoc dl,
                           SDValue Chain,
                           SDValue Op1,
                           SDValue Op2,
                           SDValue Op3,
                           unsigned Align,
                           bool isVolatile,
                           MachinePointerInfo DstPtrInfo,
                           MachinePointerInfo SrcPtrInfo) const;

  /// EmitTargetCodeForMemset - Emit target-specific code that performs a
  /// memset. This can be used by targets to provide code sequences for cases
  /// that don't fit the target's parameters for simple stores and can be more
  /// efficient than using a library call. This function can return a null
  /// SDValue if the target declines to use custom code and a different
  /// lowering strategy should be used.
  virtual SDValue
  EmitTargetCodeForMemset(SelectionDAG &DAG,
                          DebugLoc dl,
                          SDValue Chain,
                          SDValue Op1,
                          SDValue Op2,
                          SDValue Op3,
                          unsigned Align,
                          bool isVolatile,
                          MachinePointerInfo DstPtrInfo) const;
};

} // end llvm namespace

#endif // _HSAIL_SELECTION_DAG_INFO_H_
