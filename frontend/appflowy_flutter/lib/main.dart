/// PonyNotes 应用程序主入口文件
/// 
/// 该文件是 Flutter 应用程序的启动入口点，负责初始化应用程序的核心组件
/// 并启动 PonyNotes 应用程序的主要业务逻辑。
/// 
/// 主要功能：
/// 1. 初始化 ScaledWidgetsFlutterBinding 以支持应用程序界面缩放
/// 2. 调用 runAppFlowy() 启动应用程序的主要功能模块

// 导入 scaled_app 包，提供应用程序界面缩放功能
// 该包允许应用程序根据不同设备和用户偏好调整界面元素的大小
import 'package:scaled_app/scaled_app.dart';

// 导入应用程序启动模块，包含应用程序初始化和启动的核心逻辑
import 'startup/startup.dart';

/// 应用程序主入口函数
/// 
/// 这是 Flutter 应用程序的标准入口点，当应用程序启动时会首先执行此函数。
/// 该函数是异步的，因为需要等待应用程序的各种初始化任务完成。
/// 
/// 执行流程：
/// 1. 初始化 ScaledWidgetsFlutterBinding，设置界面缩放因子为 1.0（默认大小）
/// 2. 调用 runAppFlowy() 启动应用程序的完整功能
/// 
/// 返回值：Future<void> - 异步函数，无返回值
Future<void> main() async {
  // 初始化 ScaledWidgetsFlutterBinding 实例
  // 这是 Flutter 框架的一个扩展，用于处理应用程序的界面缩放功能
  // 
  // 参数说明：
  // - scaleFactor: 接受一个函数，该函数返回缩放因子
  // - (_) => 1.0: 匿名函数，忽略输入参数，始终返回 1.0
  //   这意味着应用程序将以默认大小（无缩放）启动
  //   用户可以在应用程序运行时通过设置界面调整这个缩放因子
  ScaledWidgetsFlutterBinding.ensureInitialized(
    scaleFactor: (_) => 1.0,
  );

  // 启动 PonyNotes 应用程序的主要功能
  // runAppFlowy() 是在 startup/startup.dart 中定义的异步函数
  // 它负责：
  // - 初始化应用程序的依赖注入容器
  // - 设置日志系统
  // - 初始化数据库连接
  // - 配置路由和导航
  // - 启动用户界面
  // - 处理应用程序的生命周期管理
  await runAppFlowy();
}
