# Activity Tracker

macOS 菜单栏应用，用于追踪个人应用使用情况（元数据级）。

## 功能

- 前台应用追踪（可配置采样间隔 0.5-5 秒）
- 空闲检测（IOKit，可配置阈值）
- 今日使用时长统计
- App 使用排行榜（带图标）
- 时间轴回放
- CSV / JSON 数据导出
- 开机自启动

## 隐私

- 所有数据仅保存在本地 `~/Library/Application Support/ActivityTracker/`
- 不记录键盘输入、聊天内容、密码
- 不上传任何数据到网络

## 系统要求

- macOS 13.0+
- Xcode 15.0+

## 编译运行

1. 打开 `ActivityTracker.xcodeproj`
2. 选择 "My Mac" 作为目标
3. `Cmd + R` 运行

## 使用

应用启动后常驻菜单栏（波形图标），点击查看统计面板。点击 Status 卡片可暂停/恢复追踪。

## License

MIT
