import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_project_name/models/user_model.dart';
import 'package:your_project_name/models/message_model.dart';
import 'package:your_project_name/models/notification_model.dart';
import 'package:your_project_name/models/task_model.dart';
import 'package:your_project_name/models/call_models.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('اختبار نماذج البيانات', () {
    test('اختبار نموذج المستخدم', () {
      final user = User(
        id: 'user123',
        name: 'أحمد محمد',
        email: 'ahmed@example.com',
        department: 'تقنية المعلومات',
      );
      
      expect(user.role, 'employee'); // القيمة الافتراضية
    });

    test('اختبار نموذج الرسالة', () {
      final message = Message.createText(
        chatId: 'chat123',
        senderId: 'user123',
        receiverId: 'user456',
        content: 'مرحباً',
      );
      
      expect(message.type, 'text');
    });

    test('اختبار نموذج الإشعار', () {
      final notification = Notification.createMessageNotification(
        userId: 'user456',
        senderId: 'user123',
        senderName: 'أحمد',
        messageText: 'test',
        chatId: 'chat123',
      );
      
      expect(notification.type, 'message');
    });

    test('اختبار نموذج المكالمة', () {
      final call = Call(
        id: 'call123',
        callerId: 'user123',
        callerName: 'أحمد',
        receiverId: 'user456',
        receiverName: 'محمد',
        status: CallStatus.ongoing,
        startTime: DateTime.now(),
      );
      
      expect(call.status, CallStatus.ongoing);
    });
  });
}
      
      expect(call.id, 'call123');
      expect(call.callerId, 'user123');
      expect(call.callerName, 'أحمد محمد');
      expect(call.callerImage, 'https://example.com/ahmed.jpg');
      expect(call.receiverId, 'user456');
      expect(call.receiverName, 'محمد علي');
      expect(call.receiverImage, 'https://example.com/mohamed.jpg');
      expect(call.status, CallStatus.ongoing);
      expect(call.startTime, DateTime(2025, 4, 11, 10, 30));
      expect(call.endTime, null);
      
      // اختبار تحويل المكالمة إلى Map
      final callMap = call.toMap();
      expect(callMap['callerId'], 'user123');
      expect(callMap['callerName'], 'أحمد محمد');
      expect(callMap['callerImage'], 'https://example.com/ahmed.jpg');
      expect(callMap['receiverId'], 'user456');
      expect(callMap['receiverName'], 'محمد علي');
      expect(callMap['receiverImage'], 'https://example.com/mohamed.jpg');
      expect(callMap['status'], 'ongoing');
      
      // اختبار إنشاء مكالمة من Map
      final callFromMap = Call.fromMap('call123', callMap);
      expect(callFromMap.id, 'call123');
      expect(callFromMap.callerId, 'user123');
      expect(callFromMap.callerName, 'أحمد محمد');
      expect(callFromMap.callerImage, 'https://example.com/ahmed.jpg');
      expect(callFromMap.receiverId, 'user456');
      expect(callFromMap.receiverName, 'محمد علي');
      expect(callFromMap.receiverImage, 'https://example.com/mohamed.jpg');
      expect(callFromMap.status, CallStatus.ongoing);
      
      // اختبار تحديث حالة المكالمة
      final endedCall = call.copyWith(
        status: CallStatus.ended,
        endTime: DateTime(2025, 4, 11, 10, 35),
      );
      expect(endedCall.status, CallStatus.ended);
      expect(endedCall.endTime, DateTime(2025, 4, 11, 10, 35));
      
      // اختبار حساب مدة المكالمة
      expect(endedCall.duration.inMinutes, 5);
      
      // اختبار الحصول على نص حالة المكالمة
      expect(call.statusText, 'جارية');
      expect(endedCall.statusText, 'منتهية');
    });
  });
}
