# Arch Linux Calamares 安装程序配置

Arch Linux 的 [Calamares](https://calamares.io) 安装器配置文件集。

---

## 目录结构

```
.
├── settings.conf                # 主配置（模块顺序、全局行为）
├── branding/arch/
│   ├── branding.desc            # 品牌信息（名称、颜色、图片、幻灯片）
│   ├── archlinux.png            # ⚠ 需要替换：Arch Linux Logo
│   ├── languages.png            # 欢迎页插画
│   ├── show.qml                 # 安装动画幻灯片
│   └── stylesheet.qss           # 样式表
└── modules/
    ├── welcome.conf              # 欢迎页 + 系统检查
    ├── locale.conf               # 语言/时区选择
    ├── keyboard.conf             # 键盘布局
    ├── partition.conf            # 磁盘分区
    ├── users.conf                # 用户创建
    ├── packages.conf             # 软件包安装（pacman）
    ├── bootloader.conf           # GRUB/systemd-boot 引导器
    ├── initcpiocfg.conf          # mkinitcpio.conf 配置
    ├── initcpio.conf             # mkinitcpio 执行
    ├── machineid.conf            # 生成唯一 machine-id
    ├── fstab.conf                # 生成 fstab/crypttab
    ├── mount.conf                # 分区挂载 + btrfs 子卷
    ├── umount.conf               # 安装完成后的卸载
    ├── displaymanager.conf       # 登录管理器（SDDM/LightDM/GDM）
    ├── networkcfg.conf           # 网络配置
    ├── services-systemd.conf     # 启用/禁用 systemd 服务
    ├── hwclock.conf              # 硬件时钟（UTC）
    ├── localecfg.conf            # locale 配置写入
    ├── finished.conf             # 完成页 + 重启
    ├── unpackfs.conf             # [默认] squashfs 解包
    ├── shellprocess-pacstrap.conf    # [备选] pacstrap 安装
    └── shellprocess-postinstall.conf # [可选] chroot 后命令
```

---

## 快速开始

### 1. 放置 logo

```bash
# 把 Arch logo（80x80 以上方形 PNG）放到：
# branding/arch/archlinux.png
```

### 2. 部署配置（二选一）

**开发测试：**
```bash
calamares -c ~/calamares/
```

**系统安装（root）：**
```bash
cp settings.conf /etc/calamares/
cp -r branding/      /etc/calamares/
cp -r modules/*.conf /etc/calamares/modules/
# 然后直接运行 calamares
```

> ⚠ `/etc/calamares/` 中的文件优先级高于 `/usr/share/calamares/`。
> 只放你需要覆盖的 .conf 文件进去即可，不用复制全部。

---

## 选择基础系统部署方式

Calamares 需要把 Arch 基础系统部署到目标磁盘上。有两种方式：

### 方式A（默认）：squashfs 镜像

先制作一个压缩的基础系统镜像：

```bash
# 在编译 ISO 时：
mkarchroot /tmp/rootfs base
mksquashfs /tmp/rootfs /path/to/airootfs.sqfs -comp xz -b 1M
```

然后把镜像放到你的 ISO 里，`unpackfs.conf` 指向它。

> 这是 Manjaro、EndeavourOS、CachyOS 等发行版采用的方式，
> 优点是安装速度快、不受网络影响。

### 方式B：pacstrap

修改 `settings.conf`：

```yaml
# 1. 在 instances 里添加：
instances:
  - id:       pacstrap
    module:   shellprocess
    config:   shellprocess-pacstrap.conf

# 2. 在 exec 序列中，把 unpackfs 替换为：
#    - mount       （保留）
#    - shellprocess@pacstrap     （替换 unpackfs）
#    - machineid   （保留）
```

> 优点：纯净、实时从仓库下载最新包
> 缺点：需要联网、速度较慢

---

## 各文件修改指南

### 如果你要定制自己的发行版

需要改这些地方：

| 文件 | 修改要点 |
|------|---------|
| `branding/arch/branding.desc` | 改 `productName`、配色、Logo |
| `settings.conf` | 改 `branding` 名字（和文件夹一致） |
| `modules/packages.conf` | 改安装哪些包（加桌面环境、驱动等） |
| `modules/partition.conf` | 调分区大小、默认文件系统 |
| `modules/bootloader.conf` | 改 `kernelParams`、引导器类型 |
| `modules/services-systemd.conf` | 改开机自启的服务 |

### 如果你想精简模块

有些模块可以安全地注释掉（从 `settings.conf` 的 `sequence` 中移除）：

| 模块 | 能不能删 | 影响 |
|------|---------|------|
| `networkcfg` | 可 | 不配网络，得自己想办法设置 |
| `displaymanager` | 可 | 不配登录管理器，开机进 tty |
| `hwclock` | 可 | 不设硬件时钟，系统时间可能不准 |
| `services-systemd` | 可 | 所有服务默认不启用 |
| `machineid` | 可 | systemd 会自生成，但可能重复 |

### 如果你要添加模块

1. 把 .conf 文件放到 `modules/`
2. 在 `settings.conf` 的 `sequence.exec` 中添加模块名
3. 如果有多个实例，先在 `instances` 中注册，再用 `module@id` 引用

---

## Arch 安装流程对应关系

Arch Wiki 安装指南步骤  →  Calamares 模块

| Arch 安装步骤 | Calamares 模块 |
|--------------|----------------|
| 分区磁盘 | `partition`（用户交互）→ `partition`（执行） |
| 格式化分区 | `partition`（内建） |
| 挂载文件系统 | `mount` |
| 连接网络 | `packages`（安装 NetworkManager）+ `services-systemd`（启用） |
| 安装基础包 | `unpackfs` 或 `shellprocess-pacstrap` + `packages` |
| Fstab | `fstab` |
| Chroot 配置 | 各模块自动在 chroot 中运行 |
| 时区 | `locale` → `hwclock` |
| 本地化 | `locale` + `localecfg` |
| 网络配置 | `networkcfg` + `services-systemd` |
| Initramfs | `initcpiocfg` → `initcpio` |
| Root 密码 | `users` |
| 引导器 | `bootloader` |
| 重启 | `finished` |

---

## 排错

```bash
# 运行并查看详细日志
calamares -c ~/calamares/ -d 2>&1 | tee calamares.log

# 只检查配置不启动 GUI
calamares -c ~/calamares/ -X
```

常见问题：

- **"No QML directory"** → 确保 `qml/` 符号链接存在：
  ```bash
  ln -s /usr/share/calamares/qml ~/calamares/qml
  ```
- **"Slideshow file does not exist"** → 确保 `branding/arch/show.qml` 存在
- **找不到模块 .so 文件** → 确保安装了对应的 calamares 模块包

---

## 参考

- [Calamares Wiki](https://github.com/calamares/calamares/wiki)
- [Arch Linux 安装指南](https://wiki.archlinux.org/title/Installation_guide)
- [GRUB - Arch Wiki](https://wiki.archlinux.org/title/GRUB)
- [Mkinitcpio - Arch Wiki](https://wiki.archlinux.org/title/Mkinitcpio)
- [Pacman - Arch Wiki](https://wiki.archlinux.org/title/Pacman)
