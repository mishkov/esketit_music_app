enum EmailValidationError { empty, invalid }

enum PasswordValidationError { empty, tooShort }

final class AuthCredentialsValidator {
  const AuthCredentialsValidator._();

  static const minimumPasswordLength = 8;

  static EmailValidationError? validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return EmailValidationError.empty;
    }
    if (!text.contains('@')) {
      return EmailValidationError.invalid;
    }

    return null;
  }

  static PasswordValidationError? validateSignInPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return PasswordValidationError.empty;
    }

    return null;
  }

  static PasswordValidationError? validateSignUpPassword(String? value) {
    final text = value ?? '';
    if (text.length < minimumPasswordLength) {
      return PasswordValidationError.tooShort;
    }

    return null;
  }
}
