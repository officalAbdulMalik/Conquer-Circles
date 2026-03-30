import 'dart:io';

void main() {
  var file = File('lib/services/notification_service.dart');
  var content = file.readAsStringSync();
  
  // Replace all the standard rpc blocks
  // Regex needs to capture user_id, type, title, message optionally data
  final regex = RegExp(
    r"await _client\.rpc\(\s*'notify_user',\s*params:\s*\{([^}]+)\},\s*\);",
    multiLine: true,
  );
  
  content = content.replaceAllMapped(regex, (match) {
    var paramsStr = match.group(1)!;
    
    String getP(String name) {
      final r = RegExp("'$name':\\s*([^,]+)(?:,|\\s*\$)");
      var match = r.firstMatch(paramsStr);
      if (match == null) return '';
      return match.group(1)!.trim();
    }

    String getPString(String name) {
      // Handles multi-line strings
      final r = RegExp("'$name':\\s*(('.*?'|[^,]+(?:\n\\s*[^,]+)*))", dotAll: true);
      var match = r.firstMatch(paramsStr);
      if (match == null) return '';
      var val = match.group(1)!.trim();
      if (val.endsWith(',')) val = val.substring(0, val.length - 1).trim();
      return val;
    }
    
    var userId = getP('p_user_id');
    var type = getPString('p_type');
    var title = getPString('p_title');
    var message = getPString('p_message');
    var data = getPString('p_data');
    
    if (type.isEmpty && paramsStr.contains('isRare ?')) {
        // Special case for badge
        type = "isRare ? 'rare_badge' : 'badge_unlocked'";
        title = "isRare ? 'Legendary achievement' : 'Badge unlocked 🏆'";
        message = "isRare\n            ? 'You unlocked the rare \"\$badgeName\" badge.'\n            : 'You earned the \"\$badgeName\" badge.'";
    }
    
    var result = 'await _sendDirectNotification(\n';
    result += '      userId: $userId,\n';
    result += '      type: $type,\n';
    result += '      title: $title,\n';
    result += '      message: $message,\n';
    if (data.isNotEmpty && data != "null") {
      result += '      data: $data,\n';
    }
    result += '    );';
    return result;
  });

  file.writeAsStringSync(content);
}
