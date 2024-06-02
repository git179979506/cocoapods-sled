### 获取帮助文档
```bash
bundle exec pod install --help
bundle exec pod install device --help
bundle exec pod install simulator --help
```

### 开启二进制

cocoapods-sled 给`pod install`添加了两个子命令`device`和`simulator`，分别对应真机和模拟器。
> 由于没有进行预编译，二进制缓存是从日常开发产生的缓存 DerivedData 中提取的，无法保证真机和模拟器同时编译并进行包合并，需要手动选择真机或模拟器，这样实现基本满足大多数日常开发场景和打包机打包。

**使用`device`子命令，真机调试和打包开启二进制**

```bash
bundle exec pod install device
```

**使用`simulator`子命令，模拟器调试和打包开启二进制**

```bash
bundle exec pod install simulator
```

**不使用子命令，则不触发二进制逻辑，使用源码（pod install 原逻辑）**

```bash
bundle exec pod install
```

使用上面的命令就可以开启二进制了，是不是很简单，当然插件还提供了丰富的参数和配置用于适配更正开发场景需求。

### 命令行参数说明

- `--no-binary-pods=name`: 禁用指定的 Pod 二进制缓存，多个 Pod 名称用","分隔，优先级高于 `--all-binary`

    *日常开发中，可以和`--all-binary`配合使用，忽略 Podfile 配置，并指定 pod 使用源码进行开发，避免 Podfile 同时提交协作冲突*

- `--all-binary`: 强制使用二进制缓存，忽略 Podfile 中 `:binary => false` 设置

    *跟`--no-binary-pods=name`配合使用，或者在打包机中忽略 Podfile 配置强制开启二进制*
    
- `--configuration=[Debug|Release|自定义]`: 编译配置用于生产缓存路径(Debug、Release、自定义)，不传则不区分共用，一般用于打包机
    
    *对应 Xcode Build Configuration，支持自定义，当不传此参数时所有configuration产物共用，一般在打包机才需要区分不同 configuration，避免出现Debug、Release环境混乱。*

- `--header-search-path`: 生成 Header Search Path，一般用于打包机

    *适配 OC`import ""`方式导入头文件，头文件找不到的情况，使用改标记表示所有pod头生产Header Search Path，也可以在 Podfile 中配置（支持全局生成或单个 pod 生成）*

- `--project=name`: 工程名称，用于生成framework缓存目录，区分多个工程的缓存

    *区分多个工程，一般用于打包机，避免出现一些奇怪的问题*

- `--no-dev-pod`: 关闭 Development Pods 二进制缓存，默认是开启的
    *默认情况 Development Pods 也是开启二进制的，用于适配部分三方库使用  Development Pods 导入的情况，需要注意的是：当 Development Pod 所在目录有变更时不会使用二进制。*

- `--force-sync-dev-pod`: 强制缓存 Development Pods 编译结果，忽略本地修改检查，默认本地有修改时不缓存，一般用于打包机

    *Development Pods 开启二进制时，忽略本地变更检查，一般用于打包机，默认本地有修改时不缓存*

- `--inhibit-all-warnings`: 强制关闭警告，忽略 Podfile 中的配置，一般用于打包机

    *关闭所有 pod 的编译警告，一般用于打包机，减少打包日志输出，方便排查打包失败原因*

- `--cache-limit=num`: 指定每个 Pod 缓存存储上限数量，小于 3 无效，一般用于打包机

    *默认上限是 4 个，可按需调整，缓存数量上限越大则缓存命中率越高，反之越低，⚠️注意磁盘不要被撑爆*

- `--dep-check=[single|all]`: 检查依赖库版本是否发生变更，single：只检查直接依赖，all：检查全部依赖，一般用于打包机

    *用于解决ARC不对齐问题，一般使用`--dep-check=single`即可，详见常见问题部分*

- `--check-xcode-version`: 检查xcode版本，不同版本打包不复用，使用 `xcodebuild -version` 获取版本信息，一般用于打包机

    *用于区分不同版本Xcode打出的包，一般用于打包机*


### Podfile 配置说明

安装 `cocoapods-sled` 插件后，通过 `device` 和 `simulator` 子命令就可以触发二进制缓存复用逻辑，不配置 Podfile 也可以正常工作，在 Podfile 中的一些固定配置可以简化命令行参数。

比如可以配置生成 Header Search Paths：`sled_enable_generate_header_search_paths!`，这样命令行就可以省略参数 `--header-search-path`。

Podfile 中的配置不会影响打包机打包，打包机上可通过参数 `--all-binary` 配置所有 pod 强制启用二进制。

```ruby
# 声明需要使用插件 cocoapods-sled
plugin 'cocoapods-sled'

# 标记生成 HEADER SEARCH PATHS
# 用于适配OC使用 #import "" 导入库头文件的情况，默认不生成
# 单个库可通过 :hsp => true | false 设置
sled_enable_generate_header_search_paths!

# 关闭 Development Pod 二进制缓存，默认开启
sled_disable_binary_cache_for_dev_pod!

# 与 :binary => :ignore 等效，用于没有明确依赖的库
sled_disable_binary_pods 'MOBFoundation', 'Bugly'

pod 'RxSwift', :binary => false # 关闭二进制（标记 --all-binary 时忽略该值）
pod 'RxCocoa', :binary => true # 开启二进制（默认为开启，可省略）
pod 'Bugly', :binary => :ignore # 忽略，二进制不做处理（一般用于三方库本身就是二进制的情况，避免出现异常情况，优先级高于 --all-binary）

pod 'QMUIKit', :hsp => true # 生成 HEADER SEARCH PATHS，默认不生成

```

### 示例

#### case1: 开发 SledLogin 和 SledRoute 组件库，使用真机调试

##### 方案一

1.  修改 Podfile，关闭 SledLogin 和 SledRoute 的二进制

```ruby

pod 'SledLogin', :path => '../SledLogin', :binary => false # Development Pod

pod 'SledRoute', :commit => 'f02079ae', :git => "#{BASE}/SledRoute", :binary => false # External Pod

pod 'RxSwift', '6.7.0', :binary => false # Release Pod

```

2.  执行命令查找真机缓存

```bash

$ bundle exec pod install device

```

##### 方案二（推荐）

每次修改 Podfile 比较麻烦，而且多人协作会互相影响，可以使用命令行参数规避这个问题。

`--all-binary` 和 `--no-binary-pods` 组合使用，忽略 Podfile 中的 `:binary => false` 配置，指定 pod 库关闭二进制。

```bash

$ bundle exec pod install device --all-binary --no-binary-pods=SledLogin,SledRoute

```

#### case2: 切换到模拟器调试

因为我们之前使用的是真机二进制缓存，所以需要重新执行命令手动切换到模拟器

```bash

$ bundle exec pod install simulator --all-binary --no-binary-pods=SledLogin,SledRoute

```

#### case3: 打包机打包

```bash
# 使用 bundler 保证版本统一
# --all-binary: 强制开启
# --configuration=[Debug|Release|自定义]： 区分不同configuration，避免环境混乱
# --force-sync-dev-pod: 强制开启 Development Pods 二进制，忽略本地变更
# --dep-check=single: 检查直接依赖变更，用于修复偶发的ARC不对齐问题
# --check-xcode-version: 不同版本Xcode编译结果不共用
# --cache-limit=12: 缓存上限数量改为12
# --header-search-path: 全局生成Header Search Path，根据你的项目情况而定，最好不使用
# --project=xxx: 区分不同项目的编译结果

bundle exec pod install device --all-binary --configuration=[Debug|Release|自定义] --force-sync-dev-pod --dep-check=single --check-xcode-version --cache-limit=12 [--header-search-path] [--project=xxx]
```
