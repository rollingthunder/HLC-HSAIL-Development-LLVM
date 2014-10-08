#ifndef _HSAILDEVICEINFO_H_
#define _HSAILDEVICEINFO_H_
#include <string>
namespace llvm
{
  class HSAILDevice;
  class HSAILSubtarget;
  namespace HSAILDeviceInfo
  {
    // Each Capabilities can be executed using a hardware instruction,
    // emulated with a sequence of software instructions, or not
    // supported at all.
    enum ExecutionMode {
      Unsupported = 0, // Unsupported feature on the card(Default value)
      Software, // This is the execution mode that is set if the
      // feature is emulated in software
      Hardware  // This execution mode is set if the feature exists
        // natively in hardware
    };

    // Any changes to this needs to have a corresponding update to the
    // twiki page GPUMetadataABI
    enum Caps {
      HalfOps          = 0x1,  // Half float is supported or not.
      DoubleOps        = 0x2,  // Double is supported or not.
      ByteOps          = 0x3,  // Byte(char) is support or not.
      ShortOps         = 0x4,  // Short is supported or not.
      LongOps          = 0x5,  // Long is supported or not.
      Images           = 0x6,  // Images are supported or not.
      ByteStores       = 0x7,  // ByteStores available(!HD4XXX).
      ConstantMem      = 0x8,  // Constant/CB memory.
      LocalMem         = 0x9,  // Local/LDS memory.
      PrivateMem       = 0xA,  // Scratch/Private/Stack memory.
      RegionMem        = 0xB,  // OCL GDS Memory Extension.
      FMA              = 0xC,  // Use HW FMA or SW FMA.
      ArenaSegment     = 0xD,  // Use for Arena UAV per pointer 12-1023.
      MultiUAV         = 0xE,  // Use for UAV per Pointer 0-7.
      PPAMode          = 0xF,  // UAV Per Pointer Allocation Mode capability
      NoAlias          = 0x10, // Cached loads.
      Signed24BitOps   = 0x11, // Peephole Optimization.
      // Debug mode implies that no hardware features or optimizations
      // are performned and that all memory access go through a single
      // uav(Arena on HD5XXX/HD6XXX and Raw on HD4XXX).
      Debug            = 0x12, // Debug mode is enabled.
      CachedMem        = 0x13, // Cached mem is available or not.
      BarrierDetect    = 0x14, // Detect duplicate barriers.
      Semaphore        = 0x15, // Flag to specify that semaphores are supported.
      ByteLDSOps       = 0x16, // Flag to specify if byte LDS ops are available.
      ArenaVectors     = 0x17, // Flag to specify if vector loads from arena work.
      TmrReg           = 0x18, // Flag to specify if Tmr register is supported.
      NoInline         = 0x19, // Flag to specify that no inlining should occur.
      MacroDB          = 0x1A, // Flag to specify that backend handles macrodb.
      HW64BitDivMod    = 0x1B, // Flag for backend to generate 64bit div/mod.
      ArenaUAV         = 0x1C, // Flag to specify that arena uav is supported.
      PrivateUAV       = 0x1D, // Flag to specify that private memory uses uav's.
      // If more capabilities are required, then
      // this number needs to be increased.
      // All capabilities must come before this
      // number.
      MaxNumberCapabilities = 0x20
    };

    extern bool is64bit;
  } // namespace HSAILDeviceInfo
  llvm::HSAILDevice*
    getDeviceFromName(const std::string &name, llvm::HSAILSubtarget *ptr, bool is64bit = false, bool is64on32bit = false);
} // namespace llvm
#endif // _HSAILDEVICEINFO_H_
