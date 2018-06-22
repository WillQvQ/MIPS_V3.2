# MIPS_V3.2——流水线+Cache





## 演示

串口调试输出情况:

**RESET：00 00**

**正常运行：CLKS(1)    读取情况 (1)   状态码(2)   其它参数**

示例：

**01 00 00 00**	

CLKS=**01**  读取情况=**00**    状态码=**00 00**

**07 10 22 22 00 00 00 00 00 00 00 00 8C 44 00 10**  

CLKS=**07**  读取情况=**10** (读指令中)    状态码=**22 22** (icache从memory读取一整块的指令)

**状态码与其它参数**详见下表：

| 状态码 | 状态                                         | 其它参数                                   |
| ------ | -------------------------------------------- | ------------------------------------------ |
| 00 00  | 流水线正常运行，可能是alu计算，regfile读取等 |                                            |
| 11 11  | MIPS从icache读取指令的过程                   | 指令地址(4)  指令(4)                       |
| 22 22  | icache从memory读取一整块的指令               | 指令地址(4)  块首地址(4) 正在读取的指令(4) |
| 33 33  | MIPS从dcache读取数据的过程                   | 数据地址(4)  读出数据(4)                   |
| 44 44  | dcache从memory读取一整块的指令               | 数据地址(4)  块首地址(4) 正在读取的数据(4) |
| 55 55  | MIPS向dcache写入数据                         | 数据地址(4)  写入数据(4)                   |
| 66 66  | dcache向memory写入一整块的数据               | 数据地址(4)  块首地址(4) 正在写入的数据(4) |
| 77 77  | MIPS保存数据到regfile                        | 寄存器名称(2) 写入数据(4)                  |

读取情况有四种

| 代码 | 情况                 |
| ---- | -------------------- |
| 00   | 没有读指令或读写内存 |
| 10   |                      |
| 01   |                      |
| 11   |                      |



读指令和读写数据可能同时进行  部分时候**读取情况=11**，但只能显示读指令和读写数据中的一种，在我的演示方案中，我选择了优先显示读写数据的状况。



某一次演示的串口输出全记录如下：

```

```

