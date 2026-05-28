# Incremental Save Plugin

SillyTavern 插件，结合增量保存 + gzip 压缩兜底。

## 安装

### 第一步：服务端插件

将 `server/incremental-save-server.js` 复制到酒馆的 `plugins/` 目录：

**Docker:**
```bash
docker cp plugin-version/server/incremental-save-server.js sillytavern:/home/node/app/plugins/
docker restart sillytavern
```

**本地:**
```bash
cp plugin-version/server/incremental-save-server.js /path/to/SillyTavern/plugins/
# 重启酒馆
```

### 第二步：客户端扩展

在酒馆 Extension Manager 中点击\"安装扩展\"，输入本地路径或复制 `client/index.js` 到：

```
SillyTavern/public/scripts/extensions/third-party/IncSave/index.js
```

刷新页面即可。

## 工作流程

```
saveChat 调用
    │
    ├─ 只有新消息追加
    │    → POST /api/plugins/incremental-save/save-append  (几KB)
    │
    ├─ 旧消息被修改（shujuku注入记忆）
    │    → gzip 压缩全量 → POST /api/chats/save  (186MB→56MB)
    │
    └─ 首屏初次加载/追踪重置
         → gzip 压缩全量（建立追踪基线）
```

## 配置

浏览器 Console 中:

```js
// 禁用gzip（只做增量）
window.__IncSave.updateSettings({ gzipEnabled: false })

// 调低gzip阈值
window.__IncSave.updateSettings({ gzipMinBytes: 10240 })  // 10KB

// 查看当前设置
window.__IncSave.getSettings()

// 重置追踪（切换聊天后或出现问题时）
window.__IncSave.resetTracking()
```

## 与源码版对比

| | 源码版 | 插件版 |
|------|------|------|
| 安装 | 改7个源文件 | 复制2个文件 |
| 升级兼容 | 需适配 | 跨版本 |
| 增量效果 | ✓ | ✓ |
| gzip兜底 | 需另装CompressedSave | 内置 |
| 序列化开销 | 只处理新消息 | 会跑全量JSON.stringify |
| 卸载 | 重建容器 | 删除插件文件夹 |

## License

MIT
