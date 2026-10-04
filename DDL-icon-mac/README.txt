DDL 项目管理 · macOS 应用图标
================================

设计：概念 B（进度环），配色鼠尾草蓝 #8DB0C4 / 白 / 暖珊瑚 #E79B82。
按 macOS Big Sur 图标规范制作：824x824 圆角方居中于 1024x1024 画布，
四周留白，带轻微投影，透明背景。

文件说明
--------
AppIcon.icns              直接可用的 macOS 图标文件。
                          双击 .app 包 → 显示包内容 → Contents/Resources/
                          替换这个文件，或在 Info.plist 中指向它。

AppIcon.appiconset/       Xcode 资源集。把整个文件夹拖进 Xcode 项目的
                          Assets.xcassets 即可（已含 Contents.json，
                          16/32/128/256/512 pt 的 @1x @2x 全套）。

icon-master-1024.svg      矢量母版，可无损缩放 / 二次编辑。
icon-master-1024.png      1024x1024 位图母版。

小贴士
------
· macOS 的圆角和留白已经画进图里了，系统不会再帮你裁圆角，
  所以直接用即可，别再套一层圆角。
· 如果在 Mac 上想自己重新生成 .icns，可以用随附的 iconset 命名规则 +
  iconutil -c icns AppIcon.iconset
