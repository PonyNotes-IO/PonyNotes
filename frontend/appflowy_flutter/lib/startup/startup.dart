/// PonyNotes 应用程序启动模块
/// 
/// 该文件是 PonyNotes 应用程序的核心启动模块，负责管理应用程序的完整启动流程。
/// 它采用任务驱动的架构模式，通过一系列初始化任务来逐步构建应用程序的运行环境。
/// 
/// 主要功能包括：
/// - 依赖注入容器的初始化和管理
/// - 应用程序启动任务的编排和执行
/// - 多种运行模式的支持（开发、发布、测试）
/// - 并发安全的启动流程控制
/// - 插件系统的初始化和管理

// ========== 系统核心库导入 ==========
// 导入 Dart 异步编程库，提供 Future、Stream 等异步编程支持
import 'dart:async';
// 导入 Dart 文件操作库，提供文件系统访问功能
import 'dart:io';

// ========== 应用程序功能模块导入 ==========
// 导入云环境配置模块，管理云服务相关的环境变量和配置
import 'package:appflowy/env/cloud_env.dart';
// 导入桌面端浮动工具栏组件，提供文档编辑时的工具栏功能
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/desktop_floating_toolbar.dart';
// 导入链接悬停菜单组件，提供链接编辑时的交互功能
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_hover_menu.dart';
// 导入视图展开工具，用于管理应用程序中的视图展开功能
import 'package:appflowy/util/expand_views.dart';
// 导入工作区设置模块，管理用户的工作区偏好设置
import 'package:appflowy/workspace/application/settings/prelude.dart';
// 导入后端服务模块，提供与 Rust 后端的通信接口
import 'package:appflowy_backend/appflowy_backend.dart';
// 导入日志系统，提供应用程序的日志记录和调试功能
import 'package:appflowy_backend/log.dart';

// ========== Flutter 框架库导入 ==========
// 导入 Flutter 基础库，提供调试模式检测等核心功能
import 'package:flutter/foundation.dart';
// 导入 Flutter Material Design 组件库，提供 UI 组件
import 'package:flutter/material.dart';

// ========== 第三方依赖库导入 ==========
// 导入依赖注入容器，用于管理应用程序的依赖关系和生命周期
import 'package:get_it/get_it.dart';
// 导入应用程序信息获取库，用于获取应用版本、包名等信息
import 'package:package_info_plus/package_info_plus.dart';
// 导入同步锁库，提供并发控制功能，防止多线程访问冲突
import 'package:synchronized/synchronized.dart';

// ========== 本地模块导入 ==========
// 导入依赖解析器，负责解析和注册应用程序的各种依赖关系
import 'deps_resolver.dart';
// 导入应用程序入口点接口定义
import 'entry_point.dart';
// 导入启动配置类，包含应用程序启动时的各种配置参数
import 'launch_configuration.dart';
// 导入插件系统模块，管理应用程序的插件加载和运行
import 'plugin/plugin.dart';
// 导入导航观察器，用于监控应用程序的路由导航行为
import 'tasks/af_navigator_observer.dart';
// 导入文件存储任务，负责应用程序的文件存储功能初始化
import 'tasks/file_storage_task.dart';
// 导入所有启动任务的预定义集合
import 'tasks/prelude.dart';

// ========== 全局依赖注入容器 ==========
/// 全局依赖注入容器实例
/// 
/// GetIt 是一个服务定位器模式的实现，用于管理应用程序中的所有依赖关系。
/// 通过这个全局实例，应用程序的任何地方都可以获取已注册的服务和对象。
/// 
/// 主要功能：
/// - 单例模式管理各种服务
/// - 依赖注入和服务定位
/// - 对象生命周期管理
/// - 支持懒加载和工厂模式
final getIt = GetIt.instance;

// ========== 并发控制锁 ==========
/// 应用程序启动流程同步锁
/// 
/// 该锁用于防止 runAppFlowy() 函数的并发调用，确保应用程序启动流程的原子性。
/// 在多线程环境下，可能存在多个调用尝试同时启动应用程序的情况，
/// 使用同步锁可以确保同一时间只有一个启动流程在执行。
/// 
/// 使用场景：
/// - 防止重复初始化依赖注入容器
/// - 避免多次注册相同的服务
/// - 确保启动任务按正确顺序执行
final _runAppFlowyLock = Lock();

// ========== 应用程序入口点抽象类 ==========
/// 应用程序入口点接口
/// 
/// 该抽象类定义了应用程序入口点的标准接口。不同的应用程序实现
/// （如桌面版、移动版等）需要实现这个接口来创建对应的根 Widget。
/// 
/// 设计目的：
/// - 支持多平台应用程序入口
/// - 提供统一的应用程序创建接口
/// - 便于测试和模块化开发
abstract class EntryPoint {
  /// 创建应用程序根 Widget
  /// 
  /// 根据提供的启动配置创建应用程序的根 Widget。
  /// 不同的平台实现会根据配置参数创建适合的用户界面。
  /// 
  /// 参数：
  /// - config: 启动配置对象，包含应用程序启动所需的各种参数
  /// 
  /// 返回值：应用程序的根 Widget
  Widget create(LaunchConfiguration config);
}

// ========== 应用程序运行时上下文 ==========
/// 应用程序运行时上下文类
/// 
/// 该类包含应用程序运行时所需的核心上下文信息。
/// 目前主要包含应用程序数据目录的路径信息，未来可能会扩展
/// 更多的运行时上下文数据。
/// 
/// 用途：
/// - 提供应用程序数据存储路径
/// - 传递运行时环境信息
/// - 支持应用程序的文件管理功能
class FlowyRunnerContext {
  /// 构造函数
  /// 
  /// 创建一个新的运行时上下文实例，需要指定应用程序数据目录。
  /// 
  /// 参数：
  /// - applicationDataDirectory: 应用程序数据存储目录，必需参数
  FlowyRunnerContext({required this.applicationDataDirectory});

  /// 应用程序数据存储目录
  /// 
  /// 该目录用于存储应用程序的所有数据文件，包括：
  /// - 用户数据库文件
  /// - 配置文件
  /// - 缓存文件
  /// - 日志文件
  /// - 插件数据等
  /// 
  /// 在不同平台上，这个目录的位置可能不同：
  /// - macOS: ~/Library/Application Support/[AppName]
  /// - Windows: %APPDATA%/[AppName]
  /// - Linux: ~/.local/share/[AppName]
  final Directory applicationDataDirectory;
}

// ========== 应用程序启动主函数 ==========
/// 启动 PonyNotes 应用程序的主函数
/// 
/// 这是应用程序启动的核心函数，负责根据不同的运行环境（发布模式或开发模式）
/// 启动相应的应用程序实例。该函数使用同步锁确保启动过程的线程安全性。
/// 
/// 参数：
/// - isAnon: 是否以匿名模式启动应用程序，默认为 false
///   * true: 匿名模式，用户无需登录，数据仅保存在本地
///   * false: 正常模式，需要用户登录，支持云同步功能
/// 
/// 返回值：Future<void> - 异步函数，启动完成后返回
/// 
/// 运行模式说明：
/// - 发布模式 (Release): 生产环境使用，功能完整，性能优化
/// - 开发模式 (Debug): 开发环境使用，包含调试功能和测试支持
/// 
/// 线程安全：使用 _runAppFlowyLock 锁确保不会并发启动多个应用实例
Future<void> runAppFlowy({bool isAnon = false}) async {
  // 使用同步锁防止并发调用导致重复注册
  // synchronized() 方法确保同一时间只有一个启动流程在执行
  // 这对于防止以下问题至关重要：
  // 1. 依赖注入容器的重复初始化
  // 2. 启动任务的重复执行
  // 3. 资源的重复分配
  return await _runAppFlowyLock.synchronized(() async {
    // 记录应用程序重启信息，包含匿名模式状态
    // 这条日志有助于调试和监控应用程序的启动过程
    Log.info('restart AppFlowy: isAnon: $isAnon');

    // 根据 Flutter 的编译模式选择不同的启动策略
    if (kReleaseMode) {
      // ========== 发布模式启动流程 ==========
      // 在发布模式下，应用程序以生产环境配置启动
      // 特点：
      // - 性能优化，代码压缩
      // - 禁用调试功能
      // - 使用生产环境的配置
      // - 不包含测试相关的功能
      await FlowyRunner.run(
        AppFlowyApplication(),     // 创建应用程序实例
        integrationMode(),         // 获取当前集成模式（通常是 release）
        isAnon: isAnon,           // 传递匿名模式参数
      );
    } else {
      // ========== 开发/调试模式启动流程 ==========
      // 在开发模式下，应用程序包含更多的调试和测试功能
      // 特点：
      // - 包含调试信息
      // - 支持热重载
      // - 包含测试回调函数
      // - 可以自定义 Rust 环境变量
      await FlowyRunner.run(
        AppFlowyApplication(),                                      // 创建应用程序实例
        FlowyRunner.currentMode,                                   // 使用当前运行模式（develop/unitTest/integrationTest）
        didInitGetItCallback: IntegrationTestHelper.didInitGetItCallback,  // 依赖注入初始化完成后的回调，用于测试
        rustEnvsBuilder: IntegrationTestHelper.rustEnvsBuilder,             // Rust 环境变量构建器，用于测试配置
        isAnon: isAnon,                                            // 传递匿名模式参数
      );
    }
  });
}

// ========== 应用程序运行器核心类 ==========
/// 应用程序运行器类
/// 
/// FlowyRunner 是应用程序启动流程的核心管理类，负责编排和执行整个应用程序的
/// 启动流程。它采用任务驱动的架构模式，通过一系列预定义的启动任务来逐步
/// 构建应用程序的运行环境。
/// 
/// 主要职责：
/// - 管理应用程序的运行模式
/// - 初始化依赖注入容器
/// - 编排和执行启动任务序列
/// - 处理不同平台和环境的启动需求
/// - 提供应用程序生命周期管理
class FlowyRunner {
  // ========== 应用程序运行模式管理 ==========
  /// 当前应用程序运行模式
  /// 
  /// 该静态变量指定应用程序首次启动时的初始运行模式。
  /// 在后续调用 runAppFlowy() 方法时，会自动应用相同的模式。
  /// 
  /// 运行模式类型：
  /// - develop: 开发模式，包含调试功能和开发工具
  /// - release: 发布模式，生产环境使用，性能优化
  /// - unitTest: 单元测试模式，用于自动化测试
  /// - integrationTest: 集成测试模式，用于端到端测试
  /// 
  /// 模式自动检测：通过 integrationMode() 函数根据环境变量自动确定
  static var currentMode = integrationMode();

  // ========== 应用程序启动核心方法 ==========
  /// 运行应用程序的核心静态方法
  /// 
  /// 这是应用程序启动流程的主要入口点，负责初始化所有必需的组件和服务，
  /// 然后按顺序执行一系列启动任务。该方法支持多种运行模式和自定义配置。
  /// 
  /// 参数详解：
  /// - f: 应用程序入口点，实现 EntryPoint 接口，用于创建应用的根 Widget
  /// - mode: 集成运行模式，决定应用程序的运行环境和功能集
  /// - didInitGetItCallback: 依赖注入容器初始化完成后的回调函数
  ///   * 在 getIt 容器注册完所有基础服务后触发
  ///   * 用于执行依赖于 getIt 的初始化逻辑
  ///   * 主要用于测试环境的自定义初始化
  /// - rustEnvsBuilder: Rust 后端环境变量构建器函数
  ///   * 返回传递给 Rust 后端的环境变量映射
  ///   * 用于配置后端服务的运行参数
  ///   * 支持测试环境的自定义后端配置
  /// - isAnon: 匿名模式标志，默认 false
  ///   * true: 匿名模式，用户无需登录，数据仅存储在本地
  ///   * false: 正常模式，支持用户登录和云端同步
  /// 
  /// 返回值：FlowyRunnerContext - 包含应用程序运行时上下文信息
  static Future<FlowyRunnerContext> run(
    EntryPoint f,
    IntegrationMode mode, {
    Future Function()? didInitGetItCallback,
    Map<String, String> Function()? rustEnvsBuilder,
    bool isAnon = false,
  }) async {
    // ========== 第一步：设置运行模式 ==========
    // 将传入的运行模式设置为当前模式，这将影响整个应用程序的行为
    currentMode = mode;

    // ========== 第二步：配置测试环境 ==========
    // 仅在非发布模式下设置测试相关的回调函数
    // 发布模式下不需要这些测试功能，以确保生产环境的纯净性
    if (!kReleaseMode) {
      // 设置依赖注入初始化完成后的回调函数
      // 这个回调主要用于集成测试，在所有基础服务注册完成后执行自定义逻辑
      IntegrationTestHelper.didInitGetItCallback = didInitGetItCallback;
      
      // 设置 Rust 后端环境变量构建器
      // 允许测试代码自定义传递给 Rust 后端的环境变量
      IntegrationTestHelper.rustEnvsBuilder = rustEnvsBuilder;
    }

    // ========== 第三步：配置日志系统 ==========
    // 在测试模式下禁用日志输出，避免测试过程中产生过多的日志噪音
    // 这有助于提高测试执行效率和结果的可读性
    Log.shared.disableLog = mode.isTest;

    // ========== 第四步：清理之前的启动状态 ==========
    // 检查是否存在之前注册的 AppLauncher 实例
    // 如果存在，先释放其资源，防止内存泄露和状态冲突
    if (getIt.isRegistered(instance: AppLauncher)) {
      await getIt<AppLauncher>().dispose();
    }

    // 重置依赖注入容器，清理所有之前注册的服务和单例
    // 这确保每次启动都从一个干净的状态开始，避免状态污染
    await getIt.reset();

    // ========== 第五步：创建启动配置 ==========
    // 构建应用程序启动所需的配置对象
    final config = LaunchConfiguration(
      // 设置匿名模式标志
      isAnon: isAnon,
      
      // 获取应用程序版本号
      // 单元测试环境下无法使用 package_info_plus 插件，所以使用固定版本号
      // 正常环境下从平台获取真实的应用程序版本信息
      version: mode.isUnitTest
          ? '1.0.0'  // 测试环境固定版本
          : await PackageInfo.fromPlatform().then((value) => value.version),  // 从平台获取真实版本
      
      // 构建传递给 Rust 后端的环境变量
      // 如果没有提供构建器函数，则使用空的环境变量映射
      rustEnvs: rustEnvsBuilder?.call() ?? {},
    );

    // ========== 第六步：初始化依赖注入容器 ==========
    // 注册所有核心服务和组件到依赖注入容器中
    // 这包括 SDK、启动器、插件系统等基础设施
    await initGetIt(getIt, mode, f, config);
    
    // 执行依赖注入初始化完成后的回调函数
    // 这主要用于测试环境，允许在基础服务注册完成后执行自定义初始化逻辑
    await didInitGetItCallback?.call();

    // ========== 第七步：获取应用程序数据目录 ==========
    // 从应用程序数据存储服务中获取数据目录路径
    // 这个目录将用于存储所有应用程序数据，包括数据库、配置文件等
    final applicationDataDirectory =
        await getIt<ApplicationDataStorage>().getPath().then(
              (value) => Directory(value),
            );

    // ========== 第八步：配置启动任务序列 ==========
    // 从依赖注入容器中获取应用程序启动器实例
    final launcher = getIt<AppLauncher>();
    
    // 添加应用程序启动任务序列
    // 这些任务将按顺序执行，每个任务负责初始化应用程序的特定功能模块
    launcher.addTasks(
      [
        // ========== 错误处理和调试任务 ==========
        // 平台错误捕获器任务 - 必须是第一个任务
        // 用于捕获和处理平台级别的错误，在测试模式下跳过以避免干扰测试
        if (!mode.isUnitTest && !mode.isIntegrationTest)
          const PlatformErrorCatcherTask(),
          
        // 内存泄露检测器任务 - 必须是第二个任务
        // 用于检测和报告内存泄露问题，帮助开发者发现内存管理问题
        // 注意：在 memory_leak_detector.dart 中有一个 _enable 标志控制是否启用
        MemoryLeakDetectorTask(),
        
        // 调试任务 - 初始化调试相关功能
        DebugTask(),
        
        // 功能标志任务 - 初始化功能开关系统
        const FeatureFlagTask(),

        // ========== 本地化和界面初始化任务 ==========
        // 本地化初始化任务 - 设置应用程序的语言和地区设置
        const InitLocalizationTask(),
        
        // 应用程序窗口初始化任务 - 配置应用程序窗口的基本属性
        InitAppWindowTask(),

        // ========== 后端服务初始化任务 ==========
        // Rust SDK 初始化任务 - 初始化与 Rust 后端的通信
        // 传入应用程序数据目录路径，后端将使用此路径存储数据
        InitRustSDKTask(customApplicationPath: applicationDataDirectory),

        // ========== 插件和文件系统任务 ==========
        // 插件加载任务 - 加载应用程序插件，如文档编辑器、表格编辑器等
        const PluginLoadTask(),
        
        // 文件存储任务 - 初始化文件存储系统
        const FileStorageTask(),

        // ========== 应用程序界面和服务任务 ==========
        // 在测试模式下跳过界面相关的初始化任务
        if (!mode.isUnitTest) ...[
          // 应用程序信息任务 - 必须在 AppWidgetTask 之前执行
          // 用于获取设备和应用程序信息，测试环境无法获取设备信息
          const ApplicationInfoTask(),
          
          // 自动更新任务 - 必须在 ApplicationInfoTask 之后执行
          // 用于检查和处理应用程序的自动更新，在集成测试中跳过
          if (!mode.isIntegrationTest) AutoUpdateTask(),
          
          // 热键任务 - 初始化应用程序的键盘快捷键系统
          const HotKeyTask(),
          
          // AppFlowy 云服务初始化任务 - 仅在云服务启用时执行
          if (isAppFlowyCloudEnabled) InitAppFlowyCloudTask(),
          
          // 应用程序界面组件初始化任务 - 初始化主要的用户界面组件
          const InitAppWidgetTask(),
          
          // 平台服务初始化任务 - 初始化平台特定的服务
          const InitPlatformServiceTask(),
          
          // 最近使用项目服务任务 - 初始化最近访问文档的管理服务
          const RecentServiceTask(),
        ],
      ],
    );
    
    // ========== 第九步：执行启动任务 ==========
    // 按顺序执行所有注册的启动任务
    // 每个任务都会被调用其 initialize() 方法来完成初始化
    await launcher.launch();

    // ========== 第十步：返回运行时上下文 ==========
    // 创建并返回应用程序运行时上下文，包含应用程序数据目录信息
    // 这个上下文对象将被传递给应用程序的其他部分使用
    return FlowyRunnerContext(
      applicationDataDirectory: applicationDataDirectory,
    );
  }
}

// ========== 依赖注入容器初始化函数 ==========
/// 初始化依赖注入容器的核心函数
/// 
/// 该函数负责向 GetIt 容器中注册应用程序运行所需的所有核心服务和组件。
/// 这些服务包括 SDK、启动器、插件系统、UI 组件等基础设施。通过依赖注入
/// 的方式，应用程序的各个部分可以方便地获取和使用这些服务。
/// 
/// 参数说明：
/// - getIt: 全局依赖注入容器实例，用于注册和管理所有服务
/// - mode: 当前的集成运行模式，影响服务的配置和行为
/// - f: 应用程序入口点，用于创建应用程序的根 Widget
/// - config: 启动配置对象，包含应用程序启动所需的各种参数
/// 
/// 注册的服务类型：
/// - Factory: 每次请求都创建新实例的服务
/// - LazySingleton: 第一次请求时创建，之后复用同一实例的服务
/// - Singleton: 立即创建并始终复用同一实例的服务
/// 
/// 生命周期管理：
/// - 对于需要资源清理的服务，提供了 dispose 回调函数
/// - 在应用程序关闭时会自动调用这些清理函数
Future<void> initGetIt(
  GetIt getIt,
  IntegrationMode mode,
  EntryPoint f,
  LaunchConfiguration config,
) async {
  // ========== 应用程序入口点注册 ==========
  // 注册应用程序入口点工厂
  // 使用工厂模式允许在需要时创建应用程序实例
  // 主要用于创建应用程序的根 Widget
  getIt.registerFactory<EntryPoint>(() => f);
  
  // ========== 核心 SDK 注册 ==========
  // 注册 FlowySDK 懒加载单例
  // FlowySDK 是与 Rust 后端通信的核心组件，负责：
  // - 与后端服务的网络通信
  // - 数据同步和状态管理
  // - 用户身份验证
  // - 文档和数据的 CRUD 操作
  getIt.registerLazySingleton<FlowySDK>(
    () {
      return FlowySDK();
    },
    // 提供资源清理回调，确保 SDK 正确释放资源
    dispose: (sdk) async {
      await sdk.dispose();
    },
  );
  
  // ========== 应用程序启动器注册 ==========
  // 注册 AppLauncher 懒加载单例
  // AppLauncher 负责管理和执行应用程序的启动任务序列
  // 它按照预定义的顺序执行各种初始化任务
  getIt.registerLazySingleton<AppLauncher>(
    () => AppLauncher(
      // 创建启动上下文，包含启动所需的所有信息
      context: LaunchContext(
        getIt,    // 依赖注入容器引用
        mode,     // 运行模式
        config,   // 启动配置
      ),
    ),
    // 提供资源清理回调，确保启动器正确释放资源
    dispose: (launcher) async {
      await launcher.dispose();
    },
  );
  
  // ========== 插件系统注册 ==========
  // 注册插件沙箱单例
  // PluginSandbox 提供插件的安全运行环境，负责：
  // - 插件的加载和卸载
  // - 插件间的通信隔离
  // - 插件权限管理
  // - 插件生命周期管理
  getIt.registerSingleton<PluginSandbox>(PluginSandbox());
  
  // ========== UI 组件系统注册 ==========
  // 注册视图展开工具注册表单例
  // ViewExpanderRegistry 管理应用程序中的视图展开功能：
  // - 文档树的展开/折叠状态
  // - 侧边栏的展开状态
  // - 各种面板的可见性管理
  getIt.registerSingleton<ViewExpanderRegistry>(ViewExpanderRegistry());
  
  // 注册链接悬停触发器单例
  // LinkHoverTriggers 管理文档中链接的悬停交互：
  // - 链接悬停时显示编辑菜单
  // - 链接的快速预览功能
  // - 链接编辑和删除操作
  getIt.registerSingleton<LinkHoverTriggers>(LinkHoverTriggers());
  
  // 注册导航观察器单例
  // AFNavigatorObserver 监控应用程序的路由导航：
  // - 页面跳转的监控和记录
  // - 导航历史的管理
  // - 路由状态的追踪
  // - 用于分析和调试导航行为
  getIt.registerSingleton<AFNavigatorObserver>(AFNavigatorObserver());
  
  // 注册浮动工具栏控制器单例
  // FloatingToolbarController 管理文档编辑时的浮动工具栏：
  // - 工具栏的显示和隐藏
  // - 工具栏位置的计算和调整
  // - 工具栏功能按钮的状态管理
  // - 与文档编辑器的交互
  getIt.registerSingleton<FloatingToolbarController>(
    FloatingToolbarController(),
  );

  // ========== 依赖解析和扩展服务注册 ==========
  // 调用依赖解析器来注册其他服务
  // DependencyResolver 负责注册更多特定的服务，包括：
  // - 数据库服务
  // - 网络服务
  // - 文件系统服务
  // - 平台特定的服务
  // - 第三方集成服务
  await DependencyResolver.resolve(getIt, mode);
}

// ========== 启动上下文类 ==========
/// 应用程序启动上下文类
/// 
/// LaunchContext 封装了应用程序启动过程中所需的所有上下文信息。
/// 这个类作为启动任务的参数传递，为各个启动任务提供必要的运行环境信息。
/// 
/// 设计目的：
/// - 提供统一的上下文访问接口
/// - 封装启动过程中的关键配置信息
/// - 支持启动任务的参数化配置
/// - 便于测试和模块化开发
/// 
/// 使用场景：
/// - 作为 LaunchTask.initialize() 方法的参数
/// - 在启动任务中获取依赖注入容器
/// - 在启动任务中判断运行环境
/// - 在启动任务中访问启动配置
class LaunchContext {
  /// 构造函数
  /// 
  /// 创建一个新的启动上下文实例，包含启动所需的所有关键信息。
  /// 
  /// 参数：
  /// - getIt: 依赖注入容器实例，用于获取已注册的服务
  /// - env: 当前的集成运行模式，影响启动行为
  /// - config: 启动配置对象，包含启动参数
  LaunchContext(this.getIt, this.env, this.config);

  /// 依赖注入容器实例
  /// 
  /// 通过这个容器，启动任务可以获取到已注册的各种服务和组件：
  /// - FlowySDK: 核心 SDK 服务
  /// - PluginSandbox: 插件运行环境
  /// - 各种 UI 控制器和管理器
  /// - 数据库和网络服务
  /// 
  /// 使用示例：
  /// ```dart
  /// final sdk = context.getIt<FlowySDK>();
  /// final pluginSandbox = context.getIt<PluginSandbox>();
  /// ```
  GetIt getIt;
  
  /// 当前集成运行环境模式
  /// 
  /// 这个字段指示当前应用程序的运行环境，启动任务可以根据这个值
  /// 调整自己的初始化行为：
  /// - develop: 开发环境，启用调试功能
  /// - release: 生产环境，优化性能
  /// - unitTest: 单元测试环境，简化初始化
  /// - integrationTest: 集成测试环境，模拟真实环境
  /// 
  /// 使用示例：
  /// ```dart
  /// if (context.env.isTest) {
  ///   // 测试环境下的特殊处理
  /// }
  /// ```
  IntegrationMode env;
  
  /// 启动配置对象
  /// 
  /// 包含应用程序启动时的各种配置参数：
  /// - isAnon: 是否以匿名模式启动
  /// - version: 应用程序版本号
  /// - rustEnvs: 传递给 Rust 后端的环境变量
  /// 
  /// 启动任务可以根据这些配置调整初始化行为：
  /// ```dart
  /// if (context.config.isAnon) {
  ///   // 匿名模式下的特殊初始化
  /// }
  /// ```
  LaunchConfiguration config;
}

// ========== 启动任务类型枚举 ==========
/// 启动任务类型枚举
/// 
/// 定义了应用程序启动过程中不同类型的任务分类。这种分类有助于
/// 组织和管理启动任务，并可能在未来用于任务的优先级排序或并行执行。
/// 
/// 当前定义的任务类型：
/// - dataProcessing: 数据处理类任务，如数据库初始化、文件系统准备等
/// - appLauncher: 应用程序启动器类任务，如 UI 初始化、窗口创建等
/// 
/// 设计用途：
/// - 任务分类和组织
/// - 可能的并行执行优化
/// - 任务依赖关系管理
/// - 启动性能分析和监控
enum LaunchTaskType {
  /// 数据处理类任务
  /// 
  /// 这类任务主要负责应用程序启动时的数据相关初始化：
  /// - 数据库连接和初始化
  /// - 文件系统准备
  /// - 缓存清理和准备
  /// - 配置文件读取
  /// - 数据迁移和升级
  dataProcessing,
  
  /// 应用程序启动器类任务
  /// 
  /// 这类任务主要负责应用程序界面和交互相关的初始化：
  /// - UI 组件创建
  /// - 窗口初始化
  /// - 主题和样式设置
  /// - 用户界面状态恢复
  /// - 交互功能启用
  appLauncher,
}

// ========== 启动任务基类 ==========
/// 应用程序启动任务的抽象基类
/// 
/// LaunchTask 定义了应用程序启动过程中单个任务的标准接口。
/// 每个启动任务都需要继承这个基类并实现相应的初始化和清理逻辑。
/// 
/// 设计原则：
/// - 单一职责：每个任务只负责一个特定的初始化功能
/// - 可测试性：任务可以独立测试和验证
/// - 生命周期管理：支持资源的正确初始化和清理
/// - 错误处理：在任务失败时提供清晰的错误信息
/// 
/// 任务执行流程：
/// 1. AppLauncher 按顺序调用每个任务的 initialize() 方法
/// 2. 在应用程序关闭时调用每个任务的 dispose() 方法
/// 3. 如果某个任务初始化失败，整个启动流程会中断
/// 
/// 实现要求：
/// - 子类必须调用 super.initialize() 和 super.dispose()
/// - 初始化逻辑应该是幂等的（可重复执行）
/// - 应该正确处理异常情况
/// - 需要释放的资源应该在 dispose() 中清理
class LaunchTask {
  /// 构造函数
  /// 
  /// 创建一个新的启动任务实例。基类构造函数是 const 的，
  /// 这意味着子类也应该尽可能设计为 const 构造函数。
  const LaunchTask();

  /// 获取任务类型
  /// 
  /// 返回当前任务的类型分类。默认返回 dataProcessing 类型，
  /// 子类可以重写这个 getter 来指定更合适的任务类型。
  /// 
  /// 返回值：任务类型枚举值
  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  /// 任务初始化方法
  /// 
  /// 这是任务的核心方法，负责执行具体的初始化逻辑。
  /// 所有子类都必须重写这个方法来实现自己的初始化功能。
  /// 
  /// 注意事项：
  /// - 必须调用 super.initialize(context) 以确保基类逻辑执行
  /// - 应该使用 @mustCallSuper 注解确保调用父类方法
  /// - 初始化逻辑应该是异步的，支持耗时操作
  /// - 应该正确处理和传播异常
  /// 
  /// 参数：
  /// - context: 启动上下文，包含依赖注入容器、运行模式、配置等信息
  /// 
  /// 返回值：Future<void> - 异步完成的初始化操作
  @mustCallSuper
  Future<void> initialize(LaunchContext context) async {
    // 记录任务开始初始化的日志
    // 使用 runtimeType 可以在日志中显示具体的任务类名
    Log.info('LaunchTask: $runtimeType initialize');
  }

  /// 任务清理方法
  /// 
  /// 这个方法在应用程序关闭时被调用，用于清理任务创建的资源。
  /// 子类应该重写这个方法来释放自己分配的资源。
  /// 
  /// 注意事项：
  /// - 必须调用 super.dispose() 以确保基类清理逻辑执行
  /// - 应该使用 @mustCallSuper 注解确保调用父类方法
  /// - 清理逻辑应该是安全的，即使重复调用也不会出错
  /// - 应该捕获并记录清理过程中的异常，但不要向上抛出
  /// 
  /// 返回值：Future<void> - 异步完成的清理操作
  @mustCallSuper
  Future<void> dispose() async {
    // 记录任务开始清理的日志
    // 这有助于调试资源释放过程
    Log.info('LaunchTask: $runtimeType dispose');
  }
}

// ========== 应用程序启动器类 ==========
/// 应用程序启动器类
/// 
/// AppLauncher 是管理应用程序启动流程的核心组件，负责编排和执行
/// 一系列启动任务。它采用任务队列的方式，按照指定的顺序逐个执行
/// 启动任务，并提供详细的性能监控和日志记录。
/// 
/// 主要功能：
/// - 启动任务的注册和管理
/// - 按顺序执行启动任务
/// - 提供任务执行的性能监控
/// - 线程安全的任务操作
/// - 资源的生命周期管理
/// 
/// 设计特点：
/// - 线程安全：所有操作都使用同步锁保护
/// - 性能监控：记录每个任务的执行时间
/// - 错误处理：单个任务失败会中断整个启动流程
/// - 资源管理：支持任务的正确清理和释放
/// 
/// 使用流程：
/// 1. 创建 AppLauncher 实例
/// 2. 使用 addTask() 或 addTasks() 添加启动任务
/// 3. 调用 launch() 执行所有任务
/// 4. 在应用程序关闭时调用 dispose() 清理资源
class AppLauncher {
  /// 构造函数
  /// 
  /// 创建一个新的应用程序启动器实例，需要提供启动上下文信息。
  /// 
  /// 参数：
  /// - context: 启动上下文，包含依赖注入容器、运行模式、配置等信息
  ///   这个上下文会传递给每个启动任务，为任务提供必要的运行环境
  AppLauncher({
    required this.context,
  });

  /// 启动上下文实例
  /// 
  /// 包含应用程序启动过程中所需的所有上下文信息：
  /// - 依赖注入容器：用于获取已注册的服务
  /// - 运行模式：影响任务的执行行为
  /// - 启动配置：包含各种启动参数
  /// 
  /// 这个上下文会被传递给每个启动任务的 initialize() 方法
  final LaunchContext context;
  
  /// 启动任务列表
  /// 
  /// 存储所有需要执行的启动任务实例。任务会按照添加的顺序执行，
  /// 因此任务的添加顺序非常重要，需要考虑任务间的依赖关系。
  /// 
  /// 注意事项：
  /// - 任务执行顺序就是添加顺序
  /// - 前面的任务失败会导致后续任务不执行
  /// - 列表在 dispose() 时会被清空
  final List<LaunchTask> tasks = [];
  
  /// 线程同步锁
  /// 
  /// 用于保护启动器的线程安全操作，确保：
  /// - 任务添加操作的原子性
  /// - 任务执行过程不被打断
  /// - 资源清理过程的完整性
  /// 
  /// 所有对 tasks 列表的操作都必须在这个锁的保护下进行
  final lock = Lock();

  /// 添加单个启动任务
  /// 
  /// 向启动器中添加一个新的启动任务。任务会被添加到队列末尾，
  /// 在 launch() 调用时按顺序执行。
  /// 
  /// 线程安全：使用同步锁确保操作的原子性，防止并发添加造成的数据竞争。
  /// 
  /// 参数：
  /// - task: 要添加的启动任务实例
  /// 
  /// 使用示例：
  /// ```dart
  /// launcher.addTask(InitDatabaseTask());
  /// launcher.addTask(LoadConfigTask());
  /// ```
  void addTask(LaunchTask task) {
    lock.synchronized(() {
      // 记录任务添加日志，包含任务的字符串表示
      // 这有助于调试任务添加过程
      Log.info('AppLauncher: adding task: $task');
      tasks.add(task);
    });
  }

  /// 批量添加启动任务
  /// 
  /// 向启动器中批量添加多个启动任务。这是添加任务的推荐方式，
  /// 特别是在有大量任务需要添加时，可以减少锁操作的次数。
  /// 
  /// 线程安全：使用同步锁确保整个批量添加操作的原子性。
  /// 
  /// 参数：
  /// - tasks: 要添加的启动任务集合（可迭代对象）
  /// 
  /// 使用示例：
  /// ```dart
  /// launcher.addTasks([
  ///   InitDatabaseTask(),
  ///   LoadConfigTask(),
  ///   InitUITask(),
  /// ]);
  /// ```
  void addTasks(Iterable<LaunchTask> tasks) {
    lock.synchronized(() {
      // 记录批量任务添加日志，显示所有任务的类型
      // 这有助于了解启动流程中包含哪些任务
      Log.info('AppLauncher: adding tasks: ${tasks.map((e) => e.runtimeType)}');
      this.tasks.addAll(tasks);
    });
  }

  /// 执行所有启动任务
  /// 
  /// 这是启动器的核心方法，按照任务添加的顺序逐个执行所有启动任务。
  /// 每个任务的 initialize() 方法会被调用，并传入启动上下文。
  /// 
  /// 执行特点：
  /// - 顺序执行：任务按添加顺序依次执行，不会并行
  /// - 性能监控：记录每个任务和整体的执行时间
  /// - 错误传播：任何任务失败都会导致整个启动流程中断
  /// - 线程安全：整个执行过程在同步锁保护下进行
  /// 
  /// 返回值：Future<void> - 异步完成所有任务的执行
  /// 
  /// 异常处理：如果任何任务抛出异常，整个启动流程会中断并向上传播异常
  Future<void> launch() async {
    await lock.synchronized(() async {
      // 开始计时，用于监控整体启动性能
      final startTime = Stopwatch()..start();
      Log.info('AppLauncher: start initializing tasks');

      // 遍历所有任务并依次执行
      for (final task in tasks) {
        // 为每个任务单独计时，监控任务级别的性能
        final startTaskTime = Stopwatch()..start();
        
        // 执行任务的初始化方法，传入启动上下文
        // 如果任务初始化失败，异常会向上传播，中断启动流程
        await task.initialize(context);
        
        // 计算并记录任务执行时间
        final endTaskTime = startTaskTime.elapsed.inMilliseconds;
        Log.info(
          'AppLauncher: task ${task.runtimeType} initialized in $endTaskTime ms',
        );
      }

      // 计算并记录整体启动时间
      final endTime = startTime.elapsed.inMilliseconds;
      Log.info('AppLauncher: tasks initialized in $endTime ms');
    });
  }

  /// 清理启动器资源
  /// 
  /// 在应用程序关闭时调用，负责清理启动器管理的所有资源。
  /// 会依次调用每个任务的 dispose() 方法，然后清空任务列表。
  /// 
  /// 清理特点：
  /// - 逆序清理：虽然代码中是正序，但通常清理应该与初始化相反
  /// - 异常隔离：单个任务的清理失败不应影响其他任务
  /// - 线程安全：整个清理过程在同步锁保护下进行
  /// - 完整清理：确保所有任务都被清理并清空列表
  /// 
  /// 返回值：Future<void> - 异步完成所有任务的清理
  /// 
  /// 注意：这个方法应该在应用程序关闭时只调用一次
  Future<void> dispose() async {
    await lock.synchronized(() async {
      Log.info('AppLauncher: start clearing tasks');

      // 遍历所有任务并依次清理
      // 注意：这里应该考虑逆序清理，但当前代码是正序
      for (final task in tasks) {
        try {
          // 调用任务的清理方法
          // 使用 try-catch 确保单个任务的清理失败不影响其他任务
          await task.dispose();
        } catch (e) {
          // 记录清理过程中的异常，但不向上抛出
          Log.error('AppLauncher: failed to dispose task ${task.runtimeType}: $e');
        }
      }

      // 清空任务列表，释放对任务对象的引用
      tasks.clear();

      Log.info('AppLauncher: tasks cleared');
    });
  }
}

// ========== 集成运行模式枚举 ==========
/// 应用程序集成运行模式枚举
/// 
/// IntegrationMode 定义了应用程序的不同运行模式，每种模式都有特定的
/// 行为特征和功能配置。这个枚举帮助应用程序在不同环境下采用不同的
/// 初始化策略和功能配置。
/// 
/// 模式设计原则：
/// - 环境隔离：不同模式下的功能和配置互不干扰
/// - 自动检测：根据环境变量和编译标志自动确定模式
/// - 功能分层：测试模式提供最小功能集，开发模式提供调试功能，发布模式提供完整功能
/// - 性能优化：每种模式都针对其使用场景进行优化
/// 
/// 模式用途：
/// - 控制启动任务的执行范围
/// - 调整日志和调试功能的启用状态
/// - 配置不同的服务和组件
/// - 优化不同环境下的性能表现
enum IntegrationMode {
  /// 开发模式
  /// 
  /// 用于本地开发环境，提供完整的调试和开发功能：
  /// 
  /// 特性：
  /// - 启用详细的调试日志
  /// - 包含开发者工具和调试面板
  /// - 支持热重载和代码调试
  /// - 启用所有启动任务
  /// - 包含测试辅助功能
  /// - 性能监控和分析工具
  /// 
  /// 使用场景：
  /// - 本地开发调试
  /// - 功能开发和测试
  /// - 性能分析和优化
  /// - 问题排查和诊断
  develop,
  
  /// 发布模式
  /// 
  /// 用于生产环境，提供优化的用户体验：
  /// 
  /// 特性：
  /// - 代码压缩和优化
  /// - 禁用调试功能和日志
  /// - 启用所有生产功能
  /// - 性能优化配置
  /// - 安全性增强
  /// - 错误报告和分析
  /// 
  /// 使用场景：
  /// - 正式发布的应用程序
  /// - 用户生产环境
  /// - 应用商店分发版本
  /// - 企业部署环境
  release,
  
  /// 单元测试模式
  /// 
  /// 用于运行单元测试，提供最小化的运行环境：
  /// 
  /// 特性：
  /// - 禁用 UI 相关的初始化
  /// - 禁用网络和外部依赖
  /// - 使用模拟服务和数据
  /// - 快速启动和清理
  /// - 禁用日志输出
  /// - 简化的依赖注入配置
  /// 
  /// 使用场景：
  /// - 自动化单元测试
  /// - CI/CD 管道中的测试
  /// - 代码覆盖率测试
  /// - 快速功能验证
  unitTest,
  
  /// 集成测试模式
  /// 
  /// 用于运行集成测试，模拟真实的应用程序环境：
  /// 
  /// 特性：
  /// - 启用大部分真实功能
  /// - 使用真实的 UI 组件
  /// - 支持端到端测试场景
  /// - 可配置的测试环境
  /// - 测试数据管理
  /// - 行为监控和验证
  /// 
  /// 使用场景：
  /// - 端到端自动化测试
  /// - 用户流程验证
  /// - 集成功能测试
  /// - 回归测试
  integrationTest;

  // ========== 模式分类判断方法 ==========
  
  /// 判断是否为测试模式
  /// 
  /// 检查当前模式是否为任何类型的测试模式（单元测试或集成测试）。
  /// 测试模式通常需要特殊的配置和行为，如禁用某些功能、使用模拟数据等。
  /// 
  /// 返回值：
  /// - true: 当前模式是单元测试或集成测试模式
  /// - false: 当前模式是开发或发布模式
  /// 
  /// 使用示例：
  /// ```dart
  /// if (mode.isTest) {
  ///   // 测试模式下的特殊处理
  ///   useTestDatabase();
  /// }
  /// ```
  bool get isTest => isUnitTest || isIntegrationTest;

  /// 判断是否为单元测试模式
  /// 
  /// 检查当前模式是否为单元测试模式。单元测试模式提供最小化的
  /// 运行环境，适合快速执行单元测试。
  /// 
  /// 返回值：
  /// - true: 当前模式是单元测试模式
  /// - false: 当前模式不是单元测试模式
  /// 
  /// 使用示例：
  /// ```dart
  /// if (mode.isUnitTest) {
  ///   // 跳过 UI 相关的初始化
  ///   return;
  /// }
  /// ```
  bool get isUnitTest => this == IntegrationMode.unitTest;

  /// 判断是否为集成测试模式
  /// 
  /// 检查当前模式是否为集成测试模式。集成测试模式提供接近真实
  /// 的运行环境，适合端到端的功能测试。
  /// 
  /// 返回值：
  /// - true: 当前模式是集成测试模式
  /// - false: 当前模式不是集成测试模式
  /// 
  /// 使用示例：
  /// ```dart
  /// if (mode.isIntegrationTest) {
  ///   // 使用测试配置但启用 UI
  ///   useTestConfigWithUI();
  /// }
  /// ```
  bool get isIntegrationTest => this == IntegrationMode.integrationTest;

  /// 判断是否为发布模式
  /// 
  /// 检查当前模式是否为发布模式。发布模式是生产环境使用的模式，
  /// 提供最优的性能和用户体验。
  /// 
  /// 返回值：
  /// - true: 当前模式是发布模式
  /// - false: 当前模式不是发布模式
  /// 
  /// 使用示例：
  /// ```dart
  /// if (mode.isRelease) {
  ///   // 启用生产环境的优化配置
  ///   enableProductionOptimizations();
  /// }
  /// ```
  bool get isRelease => this == IntegrationMode.release;

  /// 判断是否为开发模式
  /// 
  /// 检查当前模式是否为开发模式。开发模式提供完整的调试功能
  /// 和开发工具，适合本地开发和调试。
  /// 
  /// 返回值：
  /// - true: 当前模式是开发模式
  /// - false: 当前模式不是开发模式
  /// 
  /// 使用示例：
  /// ```dart
  /// if (mode.isDevelop) {
  ///   // 启用开发者工具和调试功能
  ///   enableDeveloperTools();
  /// }
  /// ```
  bool get isDevelop => this == IntegrationMode.develop;
}

// ========== 运行模式自动检测函数 ==========
/// 自动检测当前应用程序的运行模式
/// 
/// 该函数根据环境变量和 Flutter 编译标志自动确定应用程序应该
/// 运行在哪种模式下。这种自动检测机制确保应用程序在不同环境
/// 下都能使用正确的配置和行为。
/// 
/// 检测逻辑：
/// 1. 首先检查是否存在 'FLUTTER_TEST' 环境变量
///    - 如果存在，说明是在 Flutter 测试环境中运行，返回 unitTest 模式
/// 2. 然后检查 Flutter 的 kReleaseMode 编译标志
///    - 如果为 true，说明是发布构建，返回 release 模式
/// 3. 如果以上条件都不满足，默认返回 develop 模式
/// 
/// 环境变量说明：
/// - FLUTTER_TEST: Flutter 测试框架自动设置的环境变量
///   在运行 `flutter test` 命令时会自动设置此变量
/// 
/// 编译标志说明：
/// - kReleaseMode: Flutter 框架提供的编译时常量
///   在使用 `flutter build` 命令构建发布版本时为 true
///   在使用 `flutter run` 命令运行调试版本时为 false
/// 
/// 返回值：IntegrationMode - 检测到的运行模式
/// 
/// 使用示例：
/// ```dart
/// final mode = integrationMode();
/// print('Current mode: $mode');
/// 
/// // 根据模式调整应用行为
/// switch (mode) {
///   case IntegrationMode.develop:
///     enableDebugFeatures();
///     break;
///   case IntegrationMode.release:
///     enableProductionFeatures();
///     break;
///   case IntegrationMode.unitTest:
///     setupTestEnvironment();
///     break;
///   case IntegrationMode.integrationTest:
///     setupIntegrationTestEnvironment();
///     break;
/// }
/// ```
/// 
/// 注意事项：
/// - 这个函数应该在应用程序启动早期调用
/// - 函数的返回值会影响整个应用程序的行为
/// - 在测试环境中，确保正确设置了相应的环境变量
IntegrationMode integrationMode() {
  // 检查是否在 Flutter 测试环境中运行
  // FLUTTER_TEST 环境变量由 Flutter 测试框架自动设置
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return IntegrationMode.unitTest;
  }

  // 检查是否为发布模式构建
  // kReleaseMode 是 Flutter 框架提供的编译时常量
  if (kReleaseMode) {
    return IntegrationMode.release;
  }

  // 默认情况下返回开发模式
  // 这通常发生在本地开发环境中使用 `flutter run` 命令时
  return IntegrationMode.develop;
}

// ========== 集成测试辅助类 ==========
/// 集成测试辅助工具类
/// 
/// IntegrationTestHelper 是专门为集成测试环境设计的辅助工具类，
/// 提供了在测试环境中自定义应用程序启动行为的能力。通过这个类，
/// 测试代码可以注入自定义的初始化逻辑和环境配置。
/// 
/// 设计目的：
/// - 支持测试环境的自定义初始化流程
/// - 允许测试代码配置 Rust 后端环境
/// - 提供测试专用的回调机制
/// - 隔离测试配置与生产配置
/// 
/// 使用场景：
/// - 集成测试中的自定义初始化
/// - 测试环境的特殊配置
/// - 测试数据的准备和清理
/// - 模拟外部服务和依赖
/// 
/// 注意事项：
/// - 仅在非发布模式下生效
/// - 主要用于开发和测试环境
/// - 不应在生产环境中使用
/// - 静态变量在测试间可能需要重置
class IntegrationTestHelper {
  /// 依赖注入初始化完成后的回调函数
  /// 
  /// 这个静态变量允许测试代码注册一个回调函数，该函数会在
  /// 依赖注入容器 (GetIt) 完成基础服务注册后被调用。
  /// 
  /// 使用场景：
  /// - 在基础服务注册完成后注册测试专用的服务
  /// - 替换某些服务为测试版本或模拟版本
  /// - 设置测试环境的特殊配置
  /// - 初始化测试数据和状态
  /// 
  /// 回调时机：
  /// - 在 initGetIt() 函数执行完成后
  /// - 在应用程序启动任务执行前
  /// - 在应用程序数据目录确定后
  /// 
  /// 使用示例：
  /// ```dart
  /// // 在测试代码中设置回调
  /// IntegrationTestHelper.didInitGetItCallback = () async {
  ///   // 注册测试专用的服务
  ///   getIt.registerSingleton<TestDataService>(MockTestDataService());
  ///   
  ///   // 替换网络服务为模拟版本
  ///   getIt.unregister<NetworkService>();
  ///   getIt.registerSingleton<NetworkService>(MockNetworkService());
  ///   
  ///   // 初始化测试数据
  ///   await setupTestData();
  /// };
  /// ```
  /// 
  /// 注意事项：
  /// - 回调函数应该是异步的 (Future Function())
  /// - 在回调中可以访问已注册的 getIt 服务
  /// - 回调执行期间的异常会中断应用程序启动
  /// - 测试结束后应该清理这个回调引用
  static Future Function()? didInitGetItCallback;
  
  /// Rust 后端环境变量构建器函数
  /// 
  /// 这个静态变量允许测试代码提供一个函数来构建传递给
  /// Rust 后端的环境变量。通过这种方式，测试可以自定义
  /// 后端服务的配置和行为。
  /// 
  /// 使用场景：
  /// - 配置测试专用的数据库连接
  /// - 设置后端服务的测试模式
  /// - 指定测试环境的文件路径
  /// - 启用或禁用特定的后端功能
  /// - 配置模拟外部服务的地址
  /// 
  /// 环境变量示例：
  /// ```dart
  /// IntegrationTestHelper.rustEnvsBuilder = () {
  ///   return {
  ///     'DATABASE_URL': 'sqlite:///tmp/test_db.sqlite',
  ///     'LOG_LEVEL': 'debug',
  ///     'ENABLE_CLOUD_SYNC': 'false',
  ///     'TEST_MODE': 'true',
  ///     'MOCK_EXTERNAL_SERVICES': 'true',
  ///   };
  /// };
  /// ```
  /// 
  /// 函数签名说明：
  /// - 返回类型：Map<String, String> - 环境变量的键值对映射
  /// - 参数：无参数
  /// - 执行时机：在创建 LaunchConfiguration 对象时调用
  /// 
  /// 注意事项：
  /// - 函数应该返回非空的环境变量映射
  /// - 环境变量的键和值都必须是字符串类型
  /// - 这些环境变量会传递给 Rust 后端进程
  /// - 不正确的环境变量可能导致后端初始化失败
  /// - 测试结束后应该清理这个函数引用
  static Map<String, String> Function()? rustEnvsBuilder;
}
