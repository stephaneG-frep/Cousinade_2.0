class Validators {
  const Validators._();

  static String? requiredField(String? value, {String label = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label est obligatoire';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredField(value, label: 'Email');
    if (required != null) return required;

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Format email invalide';
    }
    return null;
  }

  static String? password(String? value) {
    final required = requiredField(value, label: 'Mot de passe');
    if (required != null) return required;

    if (value!.trim().length < 6) {
      return '6 caracteres minimum';
    }
    return null;
  }
}
