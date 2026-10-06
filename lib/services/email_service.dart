import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static const _smtpUsername = String.fromEnvironment(
    'POCKIT_SMTP_USERNAME',
    defaultValue: 'imca-516@scmsgroup.org',
  );
  static const _smtpPassword = String.fromEnvironment(
    'POCKIT_SMTP_PASSWORD',
    defaultValue: 'uoly hdpm wing bdhp',
  );

  static Future<void> sendOtp(String email, String otp) async {
    final username = _smtpUsername.trim();
    final password = _smtpPassword.replaceAll(' ', '').trim();

    if (username.isEmpty || password.isEmpty) {
      throw const EmailSendException(
        'SMTP credentials are missing. Run the app with '
        'POCKIT_SMTP_USERNAME and POCKIT_SMTP_PASSWORD dart-defines.',
      );
    }

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, "Pockit")
      ..recipients.add(email)
      ..subject = "Pockit OTP Verification"
      ..text = "Your Pockit OTP code is: $otp";

    try {
      await send(message, smtpServer);
    } on MailerException catch (e) {
      throw EmailSendException(
        'Email server rejected the OTP request. Check your Gmail address, '
        'Gmail app password, and internet connection. ${e.message}',
      );
    } catch (e) {
      throw EmailSendException('Unable to send OTP email. $e');
    }
  }
}

class EmailSendException implements Exception {
  final String message;

  const EmailSendException(this.message);

  @override
  String toString() => message;
}
