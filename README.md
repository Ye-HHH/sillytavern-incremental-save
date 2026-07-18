# SillyTavern 1.18.0 增量保存补丁

基于 [ransxd/sillytavern-incremental-save](https://github.com/ransxd/sillytavern-incremental-save) 手动适配到 SillyTavern **1.18.0**。

## 功能

| 模块 | 效果 |
|------|------|
| **增量保存** | 新消息只传几KB，不再传整个186MB文件 |
| **图片代理** | 外部图片走服务端缓存，减少加载时间 |
| **Token快速估算** | 字符数÷3.35近似估算，后台异步更新精确值 |
| **CompressedSave** | 浏览器扩展，全量保存时gzip压缩兜底 |

## 原理

```
正常发消息 → hash对比旧消息未变 → POST /api/chats/save-append（只传新消息，几KB）
编辑/删消息 → 检测到变化 → 回退全量保存（安全）
行数校验失败 → 自动回退全量保存（防数据损坏）
```

## 2026-07-19 更新：修复 hash 盲区丢数据

`computeChatHash` 的 hash 算法从**消息文本长度 + swipe_id** 改为 **JSON.stringify(整条消息)**。

**旧版问题**：hash 只看 `mes.length` 和 `swipe_id`，消息的 `extra` 字段（向量数据、reasoning、token_count、media 等）不在 hash 范围内。这意味着编辑旧消息后若文本长度不变、swipe_id 不变，增量保存会误判"无变更"而跳过更新，导致 `extra` 下的数据丢失。

**修复**：改为 `JSON.stringify(m)` 对整个消息对象序列化后计算 hash，任何字段变动都会被检测到并触发正确的保存路径。

## 安装

> 先看你是哪种情况，跟着对应的步骤走就行。

---

### 情况 A：我在用云酒馆（Docker 部署，如 Google Cloud 服务器）

**第 1 步**：SSH 连上你的服务器。

**第 2 步**：依次输入以下命令（一行一行来）：

```bash
git clone https://github.com/Ye-HHH/sillytavern-incremental-save.git
```

```bash
cd sillytavern-incremental-save
```

```bash
./install.sh --docker /opt/sillytavern
```

> 如果酒馆装在别的路径，把 `/opt/sillytavern` 换成你的路径。

**第 3 步**：等脚本跑完，出现 `Done!` 就装好了。刷新酒馆页面，按 F12 → Console，看有没有 `[Save-Size]` 开头的日志。

**以后会丢吗？** 不会。脚本已经帮你做了持久化，容器重启、重建都不会消失。

---

### 情况 B：我在用本地酒馆（电脑上直接跑的）

**第 1 步**：打开终端（Windows 用 Git Bash 或 PowerShell，Mac 用终端）。

**第 2 步**：进入下载的仓库目录，运行：

```bash
./install.sh --local "你的酒馆文件夹路径"
```

例子：
```bash
./install.sh --local ~/SillyTavern
# 或
./install.sh --local "D:/SillyTavern"
```

**第 3 步**：重启酒馆（关掉重开），完成。

---

### 我还是装不上？

打开 [Issues](https://github.com/Ye-HHH/sillytavern-incremental-save/issues) 描述你的情况，带上错误截图。

## CompressedSave（可选，推荐）

在酒馆 Extension Manager 中输入安装：
```
https://github.com/IfTimeee/SillyTavern-CompressedSave.git
```

建议在设置里把 `minBytes` 调到 `102400`（100KB），避免对小请求无意义压缩。

## 涉及文件

| 容器路径 | 改动 |
|------|------|
| `src/endpoints/chats.js` | 新增 countLines、tryAppendChat、/save-append、/group/save-append |
| `src/endpoints/image-proxy.js` | 新增图片代理缓存 |
| `src/server-startup.js` | 注册 image-proxy 路由 |
| `public/script.js` | 增量保存判断 + 图片代理拦截 + Console日志 |
| `public/scripts/group-chats.js` | 群聊增量保存判断 |
| `public/scripts/chats.js` | DOMPurify 外部图片URL重写 |
| `public/scripts/tokenizers.js` | 快速token估算 + 异步回填 |

## 恢复原始

### Docker

```bash
# 恢复 docker-compose.yml 备份
cd /opt/sillytavern
cp docker-compose.yml.bak.* docker-compose.yml
docker compose down && docker compose up -d
```

### 本地

重装酒馆或从 `backups/` 目录恢复原始文件。

## 内存建议

- **5GB**：安全，余量充足（实测峰值2.6GB系统占用）
- **4GB**：危险，容易OOM
- 建议加2GB swap兜底

## License

MIT
