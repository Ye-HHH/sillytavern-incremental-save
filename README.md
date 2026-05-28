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

## 安装

### Docker

```bash
./install.sh --docker sillytavern
```

### 本地

```bash
./install.sh --local /path/to/SillyTavern
```

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

Docker重建容器即可恢复：
```bash
cd /opt/sillytavern && docker compose down && docker compose up -d
```

## 内存建议

- **5GB**：安全，余量充足（实测峰值2.6GB系统占用）
- **4GB**：危险，容易OOM
- 建议加2GB swap兜底

## License

MIT
