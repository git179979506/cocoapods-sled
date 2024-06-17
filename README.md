## 简介
Cocoapods-sled 是一个简单易用的 Cocoapods 插件，通过缓存和复用Xcode编译结果完成二进制化。它的特性：

1.  **低接入成本**：即插即用，没有预编译，也不用双私有源等基建，维护成本低。
2.  **本地缓存**：给未匹配到二进制的 pod 插入同步脚本，当 Xcode 执行构建任务时将编译结果缓存到`~/Caches/CocoaPods/Frameworks`目录下。缓存区分真机和模拟器。
3.  **二进制化处理**：自动将可复用的 pod 转换为二进制，源码和二进制丝滑切换。

Cocoapods-sled 致力于成为iOS项目构建优化的首选工具之一，帮助开发者以更低的成本实现更高效的开发流程。

## 实现思路
Xcode 本身有自己的编译缓存 DerivedData，但经常会失效。Cocoapods-sled 插件会把 DerivedData 中的编译结果缓存，当 install 时匹配到缓存就改写 spec 把源码替换为二进制，从而避免不必要的重复编译。当执行`pod install [device | simulator]`时，大概执行了以下操作：

1. 原`pod install`流程，Downloading dependencies 执行完毕后插入二进制逻辑
2. 为每个 pod 生成缓存路径
3. 去对应的缓存路径下查找是否存在缓存
  - 缓存命中：把源码替换为二进制，并进行一些可选的操作，比如生产 Header Search Path 等
  - 未命中缓存：在 Pod Target 的 `Build Phases`中插入同步脚本，从 DerivedData 提取编译结果缓存到`~/Caches/CocoaPods/Frameworks`目录下，等待下次复用
4. 继续执行`pod install`流程，从 Generating Pods project 开始

## 安装
Cocoapods-sled 的安装过程非常简洁。你可以通过以下两种方式之一进行安装：

1.  在应用程序的Gemfile中添加以下行:

    ```ruby
    gem 'cocoapods-sled'
    ```
    然后运行`bundle install`

2.  直接在终端中执行`gem install cocoapods-sled`命令进行安装。

## 使用方法

[详见文档](./documents/usage.md)

## 常见问题

[详见文档](./documents/QA.md)

## 开发计划
- [ ] 支持 library
- [ ] 支持服务器存储
- [ ] 二进制调试？

## 补充

喜欢就star❤️一下吧

QQ交流群：692296661

<img src="./resource/QRCode.jpg" width="300" height="303" alt="交流群">

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/git179979506/cocoapods-sled. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/git179979506/cocoapods-sled/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Cocoapods::Sled project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/git179979506/cocoapods-sled/blob/main/CODE_OF_CONDUCT.md).

