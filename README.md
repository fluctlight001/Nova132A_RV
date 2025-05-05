# Nova132A_RV
本项目为基于RISC-V指令集实现的单发射顺序七级流水线处理器。

使用[Golden-Trace-for-RV32](https://github.com/fluctlight001/Golden-Trace-for-RV32)进行验证。

如有学习需要，可自行拉取两个项目进行仿真学习。

# 注
目前发现在没有cache的情况下，长流水线带来的频率优势不明显，但会带来很多的控制问题。后续更新的LTS版本会酌情缩减回5级流水线。