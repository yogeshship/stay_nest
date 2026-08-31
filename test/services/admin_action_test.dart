import 'package:flutter_test/flutter_test.dart';
import 'package:stay_nest/services/admin_audit_service.dart';

void main() {
  test('admin audit validation accepts trimmed bounded values', () {
    expect(() => validateAdminActionReason(' Policy review '), returnsNormally);
    expect(() => validateAdminActionTargetId('user-1'), returnsNormally);
  });

  test('admin audit validation rejects blank, oversized, and path values', () {
    expect(() => validateAdminActionReason('   '), throwsArgumentError);
    expect(() => validateAdminActionReason('x' * 501), throwsArgumentError);
    expect(() => validateAdminActionTargetId('users/id'), throwsArgumentError);
  });
}
