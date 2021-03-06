# 编译过程概述

在我们刚开始学编程的时候，代码的执行对我们来说就像是魔法一样：我们输入一些字符串，并且把它们交给编译器就行了。对于当时的我们来说，编译仅仅意味着“IDE 上的运行按钮”（或者是命令行里面的一串神秘指令）。我们要做的就是写好代码，点击这个按钮，这些字符串就神奇地运行起来（~~或者是神奇地报错~~）了。

在我们接触了汇编语言以后，我们知道了输入的字符串会被编译为汇编语言（对于编译型语言来说），这些汇编语言导出的二进制能够直接在 CPU 上跑起来并实现我们的目标，并且我们也能够自己手工编写一些简单的汇编程序（比如写一个排序函数或者是与系统调用配合让屏幕上闪烁炫酷的 RGB 字符）。

上方的拼图和下方的拼图都找到了，但现在我们眼前还有一个问题：我们输入的源语言是怎么变成汇编语言的呢？

我们都知道答案是编译器，但编译器**具体**是怎么做的，世界上第一个编译器是怎么写的，现在我们还不清楚。所幸，我们将在接下来的旅程中弄明白这个问题。[^1]

[^1]: 剧透：是蛋先生的鸡，世界上第一个编译器是用汇编语言写的。

> 这一节的主要任务是针对编译的过程进行一个总体性质的介绍，目的是让同学们对编译的理解不再流于书本上的描述，并对编译过程形成一个大致的，能够将想法映射到代码上的印象：编译器有哪些部分，他们有什么功能，各个部分之间是如何合作的，该怎么实现。而具体的实现指导与技术点，我们将在各个 lab 中进行详细的介绍。如果将来报道出现了偏差，以每个 lab 中具体的要求为准。  
> 计算机最重要的思想之一就是分层抽象，在任意两层之间，还可以按照设计者的意愿再次添加抽象层。而软件架构的设计和实现，是为了解决现实世界的具体问题，会面临资源、财力、物力、人力、时间等多种因素的掣肘，就会诞生一些“不那么规矩”、“不那么单纯”的架构或组件/软件，它们往往会跨层次，跨模块，大模块拆小，小模块合并，甚至打破一些“金科玉律”等。    
> 相比于弄懂一个名词，更多的精力应该放在理解事物的本质上，只要把解决问题的流程和方法弄明白了，解决问题的过程中所用到的子流程、工具、方法，你爱怎么叫怎么叫，甚至自己发明名词也可以（只是与外人沟通可能会不太顺畅）。
> 所以，当你看到示例编译器和这里的介绍的做法有不同甚至是完全不一样的时候，这一般来说并不是示例编译器或者教程“错了”，而更可能是我们给问题找到了另一种解法。[^2] 

 [^2]: 引自 https://github.com/rcore-os/rCore-Tutorial-Book-v3/issues/71

------

一个常见的编译器大致分为三个部分：前端，中端与后端（在很多书上也会将中端归为后端的一部分），他们分别承担了以下的任务

- 编译器前端会将源程序读入，在进行**词法分析**和**语法分析**以后将源程序转化为一棵抽象语法树 (Abstract Syntax Tree, **AST**)，并在此基础上对语法树进行扫描，对其进行**语义分析**，检查是否有语义错误。
- 编译器的中端会对 **AST** 进行扫描，并生成对应的一层或者是多层的中间表达形式（Intermediate Representation, **IR**），并对其进行优化（LLVM IR 就是一个拥有较活跃生态的中间表达形式）。
- 编译器的后端通常会将 IR 转化为具体体系结构的**汇编代码** (MIPS, x86, arm, RISC-V, ...)，并在这个基础上做一些面向体系结构的优化。

那我们的实验最后实现的编译器和常见的编译器有什么区别呢？

1. 实际上现在大多数编译器的实现方式都是手写递归下降（比如 GCC 曾经使用的就是 YACC（BISON）的解决方案，[但他们在 3.x 的时候放弃了这个方案](http://gcc.gnu.org/wiki/New_C_Parser )），使用 ANTLR/FLEX/BISON/其他辅助分析工具的编译器比较少，因为对于不断变动和改进的语言来说，递归下降解析器是便于理解，编写和调试的。
   **但是**，我们的部分示例编译器仍然使用了分析工具。对于不会变动的语言，使用辅助工具不失是一个比较好的选择。而且不是每位同学以后都会从事编译相关的工作，能够手写递归下降解析固然很酷炫，但掌握这些工具却确实可能会在某些情况下帮上大忙（如解析一些配置文件、实现数据库前端、~~实现浏览器~~等）。
2. 我们的编译器对错误处理的要求是比较低的，当检测到错误时只需要以一个非 0 值退出就行。但这并不代表错误处理是不重要的，实际上，一个错误处理做得好的编译器能给程序员的编程体验带来很大的提升。
3. 我们在中端部分几乎只进行生成 LLVM IR 这一步，一些简单的优化将会作为挑战实验发布。
4. 我们的编译器没有传统意义上的后端，我们的实验将止步于输出 LLVM IR，这意味着你不用分配内存和寄存器等。

## 词法分析和语法分析
词法分析的作用是从左到右扫描源程序，识别出程序源代码中的标识符、保留字、整数常量、算符、分界符等单词符号（即终结符），并把识别结果返回给语法分析器，以供语法分析器使用。
语法分析是在词法分析的基础上针对所输入的终结符串建立语法树，并对不符合语法规则的程序进行报错处理。

比如对于下面的这段 MiniSysY 的代码：

``` c
int main() {
    return 0;
}
```

它在经过词法分析后变成了一个 Token 序列，而语法分析根据这个 Token 序列携带的信息产生了一棵抽象语法树。
它完整的语法分析树长这个样子：

<img src = "./../files/parsetree.png" width="400px">

双引号下的和大写的都为词法分析器产出的终结符。

词法分析和语法分析的最终结果是产生了一棵跟我们输入的 MiniSysY 程序所对应的语法树。
这个阶段实验的重点与难点根据你选择的实现方式而不同，如果你选择的是 ANTLR 或者 FLEX/BISON，那么对你来说重难点在于学习这些工具的使用方法，并在这个基础上结合你在课程中学到的知识对文法进行处理从而使其符合工具的要求；如果你选择的是手工实现递归下降，那么对你来说重难点在于自己实现语法分析的这整个过程。

## 语义分析

如果语法分析的过程成功结束了，并且输出了一棵正常的 AST, 那么说明输入的 MiniSysY 源程序是符合文法的，但一个符合文法的源程序并不一定是一个正确的源程序，比如
```c
int main() {
   return a; //a 并没有被声明和初始化
}
```
而这种错误是我们无法在词法分析和语法分析中发现的，所以，编译器还需要对语法分析得到的语句进行分析，从而了解每个程序语句具体的含义，这个过程称为**语义分析**，如果一个程序成功地通过了语义分析，那说明这个程序的含义对于编译器来说是明确的，编译器的翻译工作能够继续进行下去。值得注意的是，通过了语义分析的代码也不一定是**完全正确**的，以 C 语言为例，我们有很多时候会对内存直接进行操作（比如你的代码直接修改某个地址上的值并对其进行转型复制#%&*等魔法操作），而这些操作的正确性是不能被编译器保证的（一般称为未定义行为，UB）。

语义分析通常分为两个部分：分析符号含义和检查语义正确性，在实践中，语义分析还通常会和中间代码生成同时进行。
分析符号含义指的是对于表达式中出现的符号，找出这个符号代表的内容，这个工作主要通过符号表来实现。检查语义正确性指的是检查每条语句是否合法，比如检查每个表达式的操作数是否符合要求，每个表达式是否为语言规范中所规定的合法的表达式，使用的变量是否都经过定义等。

总的来说，在这一阶段，我们会对 AST 进行扫描（扫描几遍取决于你的实现方式），并且完成以下的检查

- **符号表构建**：声明了哪些标识符，待编译程序使用的标识符对应于哪个位置的声明。
- **类型检查**：各语句和表达式是否类型正确

如果编译器在这个阶段发现了错误，那么通常整个编译过程在这一阶段结束以后就将终止，并且报告编译错误。

### 构建符号表
符号表是编译器编译过程中的一种特殊数据结构，通常用来记录变量和函数的声明以及其他信息。在分析表达式和语句的时候，如果这些表达式或者语句引用了某些标识符，我们可以在符号表中查询这些标识符是否有对应的定义或者说信息。符号表的层次结构和作用域是一一对应的，这样做有利于查出符号是否有重定义，以及确定不同作用域引用的标识符。

### 类型检查
完成符号表建构后，我们就可以自顶向下地遍历AST,对对应的节点进行类型检查。对于静态类（statically-typed）语言，在语言设计之初，设计者都会考虑该语言支持表达哪些类型，并给出定型规则（typing rules）。在已知定型规则的情况下编码实现类型检查算法并不困难——往往只要逐条将其翻译为代码即可。
>事实上，MiniSysY语言只有`int`和`void`俩类型。类型检查的大概只有在区分`int`和`int[]`的时候会被用到。

## 三地址码与LLVM IR
在此不再赘述，LLVM IR是一种特殊的三地址码，详见[LLVM IR 快速上手](./../pre/llvm_ir_quick_primer.md)

