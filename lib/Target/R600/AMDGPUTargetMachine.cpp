//===-- AMDGPUTargetMachine.cpp - TargetMachine for hw codegen targets-----===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file
/// \brief The AMDGPU target machine contains all of the hardware specific
/// information  needed to emit code for R600 and SI GPUs.
//
//===----------------------------------------------------------------------===//

#include "AMDGPUTargetMachine.h"
#include "AMDGPU.h"
#include "R600ISelLowering.h"
#include "R600InstrInfo.h"
#include "R600MachineScheduler.h"
#include "SIISelLowering.h"
#include "SIInstrInfo.h"
#include "llvm/Analysis/Passes.h"
#include "llvm/CodeGen/MachineFunctionAnalysis.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/IR/Verifier.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/PassManager.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/raw_os_ostream.h"
#include "llvm/Transforms/IPO.h"
#include "llvm/Transforms/Scalar.h"
#include <llvm/CodeGen/Passes.h>

using namespace llvm;

extern "C" void LLVMInitializeR600Target() {
  // Register the target
  RegisterTargetMachine<AMDGPUTargetMachine> X(TheAMDGPUTarget);
}

static ScheduleDAGInstrs *createR600MachineScheduler(MachineSchedContext *C) {
  return new ScheduleDAGMILive(C, make_unique<R600SchedStrategy>());
}

static MachineSchedRegistry
SchedCustomRegistry("r600", "Run R600's custom scheduler",
                    createR600MachineScheduler);

AMDGPUTargetMachine::AMDGPUTargetMachine(const Target &T, StringRef TT,
                                         StringRef CPU, StringRef FS,
                                         TargetOptions Options, Reloc::Model RM,
                                         CodeModel::Model CM,
                                         CodeGenOpt::Level OptLevel)
    : LLVMTargetMachine(T, TT, CPU, FS, Options, RM, CM, OptLevel),
      TLOF(new TargetLoweringObjectFileELF()),
      Subtarget(TT, CPU, FS, *this), IntrinsicInfo() {
  setRequiresStructuredCFG(true);
  initAsmInfo();
}

AMDGPUTargetMachine::~AMDGPUTargetMachine() {
  delete TLOF;
}

namespace {
class AMDGPUPassConfig : public TargetPassConfig {
public:
  AMDGPUPassConfig(AMDGPUTargetMachine *TM, PassManagerBase &PM)
    : TargetPassConfig(TM, PM) {}

  AMDGPUTargetMachine &getAMDGPUTargetMachine() const {
    return getTM<AMDGPUTargetMachine>();
  }

  ScheduleDAGInstrs *
  createMachineScheduler(MachineSchedContext *C) const override {
    const AMDGPUSubtarget &ST = TM->getSubtarget<AMDGPUSubtarget>();
    if (ST.getGeneration() <= AMDGPUSubtarget::NORTHERN_ISLANDS)
      return createR600MachineScheduler(C);
    return nullptr;
  }

  void addIRPasses() override;
  void addCodeGenPrepare() override;
  bool addPreISel() override;
  bool addInstSelector() override;
  bool addPreRegAlloc() override;
  bool addPostRegAlloc() override;
  bool addPreSched2() override;
  bool addPreEmitPass() override;
};
} // End of anonymous namespace

TargetPassConfig *AMDGPUTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new AMDGPUPassConfig(this, PM);
}

//===----------------------------------------------------------------------===//
// AMDGPU Analysis Pass Setup
//===----------------------------------------------------------------------===//

void AMDGPUTargetMachine::addAnalysisPasses(PassManagerBase &PM) {
  // Add first the target-independent BasicTTI pass, then our AMDGPU pass. This
  // allows the AMDGPU pass to delegate to the target independent layer when
  // appropriate.
  PM.add(createBasicTargetTransformInfoPass(this));
  PM.add(createAMDGPUTargetTransformInfoPass(this));
}

void AMDGPUPassConfig::addIRPasses() {
  // Function calls are not supported, so make sure we inline everything.
  addPass(createAMDGPUAlwaysInlinePass());
  addPass(createAlwaysInlinerPass());
  // We need to add the barrier noop pass, otherwise adding the function
  // inlining pass will cause all of the PassConfigs passes to be run
  // one function at a time, which means if we have a nodule with two
  // functions, then we will generate code for the first function
  // without ever running any passes on the second.
  addPass(createBarrierNoopPass());
  TargetPassConfig::addIRPasses();
}

void AMDGPUPassConfig::addCodeGenPrepare() {
  const AMDGPUSubtarget &ST = TM->getSubtarget<AMDGPUSubtarget>();
  if (ST.isPromoteAllocaEnabled()) {
    addPass(createAMDGPUPromoteAlloca(ST));
    addPass(createSROAPass());
  }

  TargetPassConfig::addCodeGenPrepare();
}

bool
AMDGPUPassConfig::addPreISel() {
  const AMDGPUSubtarget &ST = TM->getSubtarget<AMDGPUSubtarget>();
  addPass(createFlattenCFGPass());
  if (ST.IsIRStructurizerEnabled())
    addPass(createStructurizeCFGPass());
  if (ST.getGeneration() >= AMDGPUSubtarget::SOUTHERN_ISLANDS) {
    addPass(createSinkingPass());
    addPass(createSITypeRewriter());
    addPass(createSIAnnotateControlFlowPass());
  } else {
    addPass(createR600TextureIntrinsicsReplacer());
  }
  return false;
}

bool AMDGPUPassConfig::addInstSelector() {
  const AMDGPUSubtarget &ST = TM->getSubtarget<AMDGPUSubtarget>();

  addPass(createAMDGPUISelDag(getAMDGPUTargetMachine()));

  if (ST.getGeneration() >= AMDGPUSubtarget::SOUTHERN_ISLANDS) {
    addPass(createSILowerI1CopiesPass());
    addPass(createSIFixSGPRCopiesPass(*TM));
    addPass(createSIFoldOperandsPass());
  }

  return false;
}

bool AMDGPUPassConfig::addPreRegAlloc() {
  const AMDGPUSubtarget &ST = TM->getSubtarget<AMDGPUSubtarget>();

  if (ST.getGeneration() <= AMDGPUSubtarget::NORTHERN_ISLANDS) {
    addPass(createR600VectorRegMerger(*TM));
  } else {
     if (getOptLevel() > CodeGenOpt::None && ST.loadStoreOptEnabled()) {
      // Don't do this with no optimizations since it throws away debug info by
      // merging nonadjacent loads.

      // This should be run after scheduling, but before register allocation. It
      // also need extra copies to the address operand to be eliminated.
      initializeSILoadStoreOptimizerPass(*PassRegistry::getPassRegistry());
      insertPass(&MachineSchedulerID, &SILoadStoreOptimizerID);
    }

    addPass(createSIShrinkInstructionsPass());
    addPass(createSIFixSGPRLiveRangesPass());
  }
  return false;
}

bool AMDGPUPassConfig::addPostRegAlloc() {
  const AMDGPUSubtarget &ST = TM->getSubtarget<AMDGPUSubtarget>();

  if (ST.getGeneration() > AMDGPUSubtarget::NORTHERN_ISLANDS) {
    addPass(createSIShrinkInstructionsPass());
  }
  return false;
}

bool AMDGPUPassConfig::addPreSched2() {
  const AMDGPUSubtarget &ST = TM->getSubtarget<AMDGPUSubtarget>();

  if (ST.getGeneration() <= AMDGPUSubtarget::NORTHERN_ISLANDS)
    addPass(createR600EmitClauseMarkers());
  if (ST.isIfCvtEnabled())
    addPass(&IfConverterID);
  if (ST.getGeneration() <= AMDGPUSubtarget::NORTHERN_ISLANDS)
    addPass(createR600ClauseMergePass(*TM));
  if (ST.getGeneration() >= AMDGPUSubtarget::SOUTHERN_ISLANDS) {
    addPass(createSIInsertWaits(*TM));
  }
  return false;
}

bool AMDGPUPassConfig::addPreEmitPass() {
  const AMDGPUSubtarget &ST = TM->getSubtarget<AMDGPUSubtarget>();
  if (ST.getGeneration() <= AMDGPUSubtarget::NORTHERN_ISLANDS) {
    addPass(createAMDGPUCFGStructurizerPass());
    addPass(createR600ExpandSpecialInstrsPass(*TM));
    addPass(&FinalizeMachineBundlesID);
    addPass(createR600Packetizer(*TM));
    addPass(createR600ControlFlowFinalizer(*TM));
  } else {
    addPass(createSILowerControlFlowPass(*TM));
  }

  return false;
}
