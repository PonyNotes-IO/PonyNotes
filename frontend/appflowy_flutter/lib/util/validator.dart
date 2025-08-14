// 手机号和邮箱校验工具类
class Validator {
  /// 校验手机号（中国大陆主流号段，禁止无效号段）
  static bool isValidPhone(String phone) {
    // 处理国际格式 +86 开头的手机号
    String cleanPhone = phone.trim();
    if (cleanPhone.startsWith('+86')) {
      cleanPhone = cleanPhone.substring(3);
    } else if (cleanPhone.startsWith('86') && cleanPhone.length == 13) {
      cleanPhone = cleanPhone.substring(2);
    }
    
    if (cleanPhone.length != 11) return false;
    if (!RegExp(r'^\d{11}$').hasMatch(cleanPhone)) return false;
    const forbidden = [
      '00000000000',
      '12345678901',
    ];
    if (forbidden.contains(cleanPhone)) return false;
    final validPrefixes = [
      // 移动
      '134', '135', '136', '137', '138', '139', '1440', '147', '148', '150',
      '151', '152',
      '157', '158', '159', '172', '178', '182', '183', '184', '187', '188',
      '195', '197', '198',
      // 联通
      '130', '131', '132', '1400', '1401', '145', '146', '155', '156', '166',
      '167', '175', '176', '185', '186', '196',
      // 电信
      '133', '1410', '149', '153', '162', '173', '174', '177', '180', '181',
      '189', '190', '191', '193', '199',
      // 虚拟运营商
      '165', '167', '1700', '1701', '1702',
    ];
    final prefix4 = cleanPhone.substring(0, 4);
    final prefix3 = cleanPhone.substring(0, 3);
    if (validPrefixes.contains(prefix4) || validPrefixes.contains(prefix3)) {
      return true;
    }
    return false;
  }

  /// 校验邮箱（符合常见邮箱规则，禁止保留域名）
  static bool isValidEmail(String email) {
    if (email.length > 254) return false;
    final atIndex = email.indexOf('@');
    if (atIndex <= 0 ||
        atIndex != email.lastIndexOf('@') ||
        atIndex == email.length - 1) return false;
    final local = email.substring(0, atIndex);
    final domain = email.substring(atIndex + 1);
    if (local.isEmpty || local.length > 64) return false;
    if (!RegExp(r'^[A-Za-z0-9._\-+]+$').hasMatch(local)) return false;
    if (RegExp(r'[._\-+]{2,}').hasMatch(local)) return false;
    if (!domain.contains('.') || domain.startsWith('.') || domain.endsWith('.'))
      return false;
    final domainParts = domain.split('.');
    final tld = domainParts.last;
    if (tld.length < 2 || RegExp(r'^\d+$').hasMatch(tld)) return false;
    const reservedDomains = ['test.com', 'example.com'];
    if (reservedDomains.contains(domain.toLowerCase())) return false;
    return true;
  }

  /// 校验输入是否为合法邮箱或手机号
  static bool isValidEmailOrPhone(String input) {
    return isValidEmail(input) || isValidPhone(input);
  }

  /// 清理手机号格式，移除国际区号
  static String cleanPhoneNumber(String phone) {
    String cleanPhone = phone.trim();
    if (cleanPhone.startsWith('+86')) {
      cleanPhone = cleanPhone.substring(3);
    } else if (cleanPhone.startsWith('86') && cleanPhone.length == 13) {
      cleanPhone = cleanPhone.substring(2);
    }
    return cleanPhone;
  }
}
