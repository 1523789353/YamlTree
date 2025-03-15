# YamlTree: 目录打印工具

以Yaml树形结构打印指定目录结构

```
用法: YamlTree [path...] [--type <type>] [--exclude <path>] [--include <path>] [--gitignore]

选项:
  path             目录路径 (默认值: 当前工作目录)
  --type <type>    过滤输出类型:
                   - file: 仅输出包含文件的目录结构
                   - dir:  仅输出目录结构
                   - all:  输出完整目录结构 (默认)
  --exclude <path> 排除指定路径 (此参数可以有多个)
  --include <path> 包含指定路径 (此参数可以有多个)
  --gitignore      遍历时遵循 .gitignore 规则
  --help           显示帮助信息
```
