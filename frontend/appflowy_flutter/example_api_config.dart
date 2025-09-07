/// 🔑 API配置示例文件
/// 
/// 要启用云服务PDF处理，请：
/// 1. 复制这个文件为 api_config.dart
/// 2. 填入你的API密钥
/// 3. 在 HybridPdfService 中导入使用

class ApiConfig {
  // Google Document AI 配置
  static const String googleDocumentAI_apiKey = 'YOUR_GOOGLE_DOCUMENT_AI_KEY';
  static const String googleDocumentAI_projectId = 'your-project-id';
  static const String googleDocumentAI_location = 'us'; // 或 'eu'
  
  // Adobe PDF Services 配置
  static const String adobe_clientId = 'YOUR_ADOBE_CLIENT_ID';
  static const String adobe_clientSecret = 'YOUR_ADOBE_CLIENT_SECRET';
  
  // AWS Textract 配置 (可选)
  static const String aws_accessKeyId = 'YOUR_AWS_ACCESS_KEY';
  static const String aws_secretAccessKey = 'YOUR_AWS_SECRET_KEY';
  static const String aws_region = 'us-east-1';
}

/// 📝 如何获取API密钥：
/// 
/// 🔵 Google Document AI:
/// 1. 访问 Google Cloud Console
/// 2. 启用 Document AI API
/// 3. 创建服务账号并下载JSON密钥
/// 4. 设置环境变量或直接使用密钥
/// 
/// 🔴 Adobe PDF Services:
/// 1. 访问 Adobe Developer Console
/// 2. 创建新项目并添加PDF Services API
/// 3. 获取Client ID和Client Secret
/// 
/// 🟡 AWS Textract:
/// 1. 访问 AWS Console
/// 2. 创建IAM用户并添加Textract权限
/// 3. 获取Access Key和Secret Key
