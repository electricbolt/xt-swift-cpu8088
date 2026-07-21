# xt-swift-cpu8088

#### 8086/8088 CPU emulation compatibility

The CPU emulator implements all *documented* 8086/8088 instructions. 

The undocumented instructions are as follows, which are *not* implemented (as you *generally* don't
write them in assembly, and your code would be incompatible with a V20 CPU):

- **0F** - `POP CS`.
- **60-6F** - Conditional jumps (identical to **70-7F**)
- **82** - 8-bit immediate group (identical to **80**).
- **C0** - `RET` - Near return (identical to **C2**).
- **C1** - `RET` - Near return (identical to **C3**).
- **C8** - `RET` - Far return (identical to **CA**).
- **C9** - `RET` - Far return (identical to **C9**).
- **D0/6** - Set minus one.
- **D1/6** - Set minus one.
- **D2/6** - Unknown.
- **D3/6** - Unknown.
- **D6** - `SALC`.
- **F1** - `LOCK` (identical to **F0**).
- **F6/1** - `TEST` (identical to **F6/0**).
- **FE/2-7** - `CALL`,`JMP`,`PUSH`.
- **FF/7** - `PUSH` (identical to **F7/6**). 

#### Installation

Add the following to your Package.swift file:

`.package(url: "https://github.com/electricbolt/xt-swift-cpu8088", from: "1.0.0")`

#### Usage

Create an instance of `CPU`, set up the initial register values and memory then `execute`. 
(See ExampleTests.swift)

```
import Testing
import XTSwiftCPU8088

class ExampleTests: CPUDelegateAdapter {

    @Test
    public func add() {
        let cpu = CPU(delegate: self)

        cpu.reg.AX.setValue(0x10)
        cpu.reg.CS.setValue(0x1000)
        cpu.reg.IP.setValue(0x0000)

        cpu.memory.setByte(SegOfs(0x1000, 0x0000), 0x05) // ADD AX,imm16
        cpu.memory.setByte(SegOfs(0x1000, 0x0001), 0x10) //   imm16 lo byte
        cpu.memory.setByte(SegOfs(0x1000, 0x0002), 0x00) //   imm16 hi byte

        cpu.execute(1)

        #expect(cpu.reg.AX.getValue() == 0x20)
    }
}
```

#### Unit tests

The CPU emulator is unit tested against [Single Step Tests](https://github.com/electricbolt/8088) 
(over 2.5 million tests) and all documented opcodes pass including exact *undocumented* flag 
behaviour (except for instructions **F6/6** `DIV` (8-bit), **F7/6** `DIV` (16-bit), **F6/7** `IDIV`
(8-bit), **F7/7** `IDIV` (16-bit), which would require a full microcode implementation of the
algorithms, these instructions clear the undocumented flags instead). All unit tests _including_ the
2.5 million Single Step Tests take about 15 seconds on an Apple MacBook Pro M4.

The Single Step Tests are **not** included in the repository due to size (1.46GB). Instead clone them
once onto your machine (they rarely change) and create a `.xt8088v2` file in your home directory that points to them:

```bash
cd ~/Documents
git clone https://github.com/electricbolt/8088
echo "~/Documents/8088" >~/.xt8088v2
```

`CPUTests.swift` will output an error with text `CPUTest opcode 00 skipped - The file “.xt8088v2” couldn’t be opened because there is no such file.` to
the console if the Single Step Tests can't be found.

#### Java/Android?

xt-swift-cpu8088 is a port of my Java based CPU emulator (and MS-DOS command line program user 
mode emulator) [XT](https://github.com/electricbolt/XT).
