## 1. ARC不对齐问题

**描述**：参考[得物 iOS 工程演进之路](https://mp.weixin.qq.com/s/Lr6tDxacQKGZ19cKdmNg1w),全工程编译产物制作：利用编译缓存，从 Xcode 编译缓存 DerivedData 中取出组件。可能会产生ARC不对齐问题，导致 EXC\_BAD\_ACCESS Crash，具体原因请查看文档。

**解决方案**：使用`--dep-check=[single|all]`参数，实际测试`--dep-check=single`可解决上述偶发问题，但受限于样本量较少，不保证测试结果准确性。

## 2. #import "" 方式导入的头文件找不到

**解决方案**：
1.  命令行使用`--header-search-path`标记，所有 Pod 都会生成 Header Search Path
2.  Podfile配置`sled_enable_generate_header_search_paths!`，所有 Pod 都会生成 Header Search Path
3.  单个 Pod 配置 `pod 'xxx', :hsp => true`，指定 Pod 生成 Header Search Path

## 3. The 'Pods-xxx' target has transitive dependencies that include statically linked binaries:

**描述**：可能是在 Podfile 中重写了 `build_as_static_framework?` `build_as_dynamic_framework?`等方法，但是没有修改 `@build_type`属性，`verify_no_static_framework_transitive_dependencies` 执行时，需要编译的 pod 库都按照修改前的 build\_type 检查，导致判断有问题报错：动态库不能依赖静态库。

**解决方案**：正确修改 `@build_type` 属性，或者使用 Cocoapods 提供的方法声明 Pod 为静态库或动态库，`use_frameworks! :linkage => :static`