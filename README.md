# release-tools

快速初始化 LoongArch64 Releases 构建项目的工具。只需一条命令，即可在当前空目录生成标准的构建脚本、Dockerfile 和 CI 配置。

## 用法

进入一个**空目录**，运行以下命令：

```bash
curl -sSL https://raw.githubusercontent.com/loongarch64-releases/release-tools/main/bootstrap.sh | bash -s -- <上游作者> <上游项目名> [你的组织名]
```

### 示例

为 `langgenius/dify-sandbox` 初始化构建环境：

```bash
mkdir dify-sandbox-loongarch && cd dify-sandbox-loongarch
curl -sSL https://raw.githubusercontent.com/loongarch64-releases/release-tools/main/bootstrap.sh | bash -s -- langgenius dify-sandbox
```

*注：`[你的组织名]` 可选，默认为 `loongarch64-releases`。*

## 生成的文件

- `scripts/build.sh`: 构建脚本
- `scripts/build_in_docker.sh`: Docker 构建封装
- `Dockerfile.build`: 构建镜像定义
- `README.md`: 项目说明（自动填充上游信息）

## 本地调试

如果你克隆了本仓库，可以直接调用 `init.sh`：

```bash
/path/to/release-tools/init.sh <上游作者> <上游项目名>
```

---
*Made for LoongArch64.*
```
