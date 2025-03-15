echo: { } // & @cls & @node "%~dpnx0" %* & @exit /b %ErrorLevel%
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const ignore = require('ignore');

// 帮助信息
const HELP_MESSAGE = `
Usage: yamlTree [path...] [--type <type>] [--exclude <path>] [--include <path>] [--gitignore]

Options:
  path             Directory paths (default: current working directory)
  --type <type>    Filter output by type:
                   - file: Only include directories with files
                   - dir:  Only include directory structure
                   - all:  Include complete directory structure (default)
  --exclude <path> Exclude specific paths (can be specified multiple times)
  --include <path> Include specific paths (can be specified multiple times)
  --gitignore      Apply .gitignore rules during traversal
  --help           Show this help message
`;

// 递归遍历目录并生成树形结构
function buildTree(dirPath, filterType = 'all', excludePaths = [], includePaths = [], useGitignore = false, ig = ignore()) {
    const stats = fs.statSync(dirPath);
    if (stats.isFile()) {
        return filterType === 'dir' ? null : path.basename(dirPath);
    }

    // 读取并解析 .gitignore 文件
    if (useGitignore) {
        const gitignorePath = path.join(dirPath, '.gitignore');
        if (fs.existsSync(gitignorePath)) {
            const gitignoreContent = fs.readFileSync(gitignorePath, 'utf8');
            ig.add(gitignoreContent);
        }
    }

    const items = fs.readdirSync(dirPath);
    const tree = [];

    items.forEach(item => {
        const itemPath = path.join(dirPath, item);

        // 检查是否在排除路径中
        if (excludePaths.some(excludePath => itemPath.startsWith(excludePath))) {
            return;
        }

        // 检查是否在包含路径中（如果包含路径不为空）
        if (includePaths.length > 0 && !includePaths.some(includePath => itemPath.startsWith(includePath))) {
            return;
        }

        // 检查是否被 .gitignore 规则排除
        if (useGitignore && ig.ignores(path.relative(dirPath, itemPath))) {
            return;
        }

        const itemTree = buildTree(itemPath, filterType, excludePaths, includePaths, useGitignore, ig);

        if (itemTree !== null) {
            if (typeof itemTree === 'string') {
                // 文件
                tree.push(itemTree);
            } else {
                // 目录
                const dirNode = {};
                dirNode[item] = itemTree;
                tree.push(dirNode);
            }
        }
    });

    // 根据 filterType 过滤空目录
    if (filterType === 'file' && tree.length === 0) {
        return null;
    }

    return tree;
}

// 解析命令行参数
function parseArgs() {
    const args = process.argv.slice(2);
    const options = {
        exclude: [],
        include: [],
        useGitignore: false,
    };

    for (let i = 0; i < args.length; i++) {
        const arg = args[i];

        if (arg === '--type') {
            options.type = args[++i]; // 获取下一个参数作为 type 的值
        } else if (arg === '--exclude') {
            options.exclude.push(args[++i]); // 获取下一个参数作为 exclude 的值
        } else if (arg === '--include') {
            options.include.push(args[++i]); // 获取下一个参数作为 include 的值
        } else if (arg === '--gitignore') {
            options.useGitignore = true;
        } else if (arg === '--help') {
            console.log(HELP_MESSAGE);
            process.exit(0);
        } else if (!arg.startsWith('--')) {
            // 将 path 参数加入 include
            options.include.push(arg);
        }
    }

    // 如果未提供 path 或 include，则默认包含当前工作目录
    if (options.include.length === 0) {
        options.include.push(process.cwd());
    }

    return options;
}

// 主函数
function main() {
    const { type = 'all', exclude = [], include = [], useGitignore = false } = parseArgs();

    if (!['file', 'dir', 'all'].includes(type)) {
        console.error(`Error: Invalid type "${type}". Valid types are: file, dir, all.`);
        process.exit(1);
    }

    // 解析包含路径和排除路径
    const includePaths = include.map(p => path.resolve(p));
    const excludePaths = exclude.map(p => path.resolve(p));

    // 构建树形结构
    const tree = {};
    includePaths.forEach(includePath => {
        if (!fs.existsSync(includePath)) {
            console.error(`Error: Path "${includePath}" does not exist.`);
            process.exit(1);
        }

        const dirName = path.basename(includePath);
        const dirTree = buildTree(includePath, type, excludePaths, includePaths, useGitignore);
        tree[dirName] = dirTree;
    });

    // 输出 YAML
    const yamlTree = yaml.dump(tree, { noRefs: true, skipInvalid: true });
    console.log(yamlTree);
}

// 运行主函数
main();
