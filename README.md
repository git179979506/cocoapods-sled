# Cocoapods-sled

Cocoapods-sled 是一个轻量且易于使用的 Cocoapods 插件，通过缓存和复用Xcode编译结果完成二进制化提升项目构建速度。它的特性为：
  
  1. **低接入成本**：易于集成，无需复杂的配置和基建即可开始优化构建流程。
  2. **编译结果缓存**：将Xcode编译结果缓存到`~/Caches/CocoaPods/Frameworks`目录下，等待复用。
  3. **二进制化处理**：自动将可复用的 pod 转换为二进制格式。 
  
  Cocoapods-sled 致力于成为iOS项目构建优化的首选工具，帮助开发者以更低的成本实现更高效的开发流程。

## 安装

在您的应用程序的 Gemfile 中添加以下行：

```ruby
gem 'cocoapods-sled'
```

然后执行：

    $ bundle install

或者自行安装：

    $ gem install cocoapods-sled

## 使用方法

### 获取帮助文档

    $ bundle exec pod install --help
    $ bundle exec pod install device --help
    $ bundle exec pod install simulator --help

### 缓存和复用真机编译结果

使用 `device` 子命令查找真机二进制缓存。

缓存命中时使用二进制替换源码，缓存未命中时会自动生成编译结果同步脚本，同步本次编译结果到缓存目录供下次使用。

默认所有 pod 都开启二进制，可以在命令行或 Podfile 中指定 pod 关闭二进制。

    $ bundle exec pod install device

### 缓存和复用模拟器编译结果

使用 `simulator` 子命令查找模拟器二进制缓存。

缓存命中时使用二进制替换源码，缓存未命中时会生成编译结果同步脚本，同步本次编译结果到缓存目录供下次使用。

默认所有 pod 都开启二进制，可以在命令行或 Podfile 中指定 pod 关闭二进制。

    $ bundle exec pod install simulator

### 全部使用源码

不使用 `device` 和 `simulator` 子命令，则执行原 install 流程，全部使用源码

    $ bundle exec pod install


### 命令行参数说明

- `--no-binary-pods=name`: 禁用指定的 Pod 二进制缓存，多个 Pod 名称用","分隔，优先级高于 `--all-binary`
- `--all-binary`: 强制使用二进制缓存，忽略 Podfile 中 `:binary => false` 设置
- `--header-search-path`: 生成 Header Search Path，一般用于打包机
- `--project=name`: 工程名称，用于生成framework缓存目录，区分多个工程的缓存
- `--no-dev-pod`: 关闭 Development Pods 二进制缓存，默认是开启的
- `--force-sync-dev-pod`: 强制缓存 Development Pods 编译结果，忽略本地修改检查，默认本地有修改时不缓存，一般用于打包机
- `--inhibit-all-warnings`: 强制关闭警告，忽略 Podfile 中的配置，一般用于打包机
- `--cache-limit=num`: 指定每个 Pod 缓存存储上限数量，小于 3 无效，一般用于打包机
- `--dep-check=[single|all]`: 检查依赖库版本是否发生变更，single：只检查直接依赖，all：检查全部依赖，一般用于打包机
- `--check-xcode-version`: 检查xcode版本，不同版本打包不复用，使用 `xcodebuild -version` 获取版本信息，一般用于打包机
- `--configuration=[Debug|Release|自定义]`: 编译配置用于生产缓存路径(Debug、Release、自定义)，不传则不区分共用，一般用于打包机

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

1. 修改 Podfile，关闭 SledLogin 和 SledRoute 的二进制

```ruby
pod 'SledLogin', :path => '../SledLogin', :binary => false # Development Pod
pod 'SledRoute', :commit => 'f02079ae', :git => "#{BASE}/SledRoute", :binary => false # External Pod
pod 'RxSwift', '6.7.0', :binary => false # Release Pod
```
    
2. 执行命令查找真机缓存

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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/git179979506/cocoapods-sled. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/git179979506/cocoapods-sled/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Cocoapods::Sled project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/git179979506/cocoapods-sled/blob/main/CODE_OF_CONDUCT.md).
