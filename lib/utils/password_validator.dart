class PasswordValidator {
  /// Validates if password meets minimum requirements
  /// Returns null if valid, error message if invalid
  static String? validate(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (password.length > 50) {
      return 'Password must be less than 50 characters';
    }
    
    return null; // Password is valid
  }
  
  /// Get password strength (0-4) based on length
  /// 0 = Very Weak, 1 = Weak, 2 = Fair, 3 = Strong, 4 = Very Strong
  static int getStrength(String password) {
    if (password.length < 6) return 0;
    if (password.length < 8) return 1;
    if (password.length < 10) return 2;
    if (password.length < 12) return 3;
    return 4;
  }
  
  /// Get password strength label
  static String getStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Strong';
      case 4:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }
  
  /// Get password strength color
  static int getStrengthColor(int strength) {
    switch (strength) {
      case 0:
        return 0xFFEF4444; // Red
      case 1:
        return 0xFFF97316; // Orange
      case 2:
        return 0xFFFBBF24; // Yellow
      case 3:
        return 0xFF22C55E; // Green
      case 4:
        return 0xFF10B981; // Emerald
      default:
        return 0xFF6B7280; // Gray
    }
  }
  
  /// Get list of password requirements
  static List<PasswordRequirement> getRequirements(String password) {
    return [
      PasswordRequirement(
        label: 'At least 8 characters',
        isMet: password.length >= 8,
      ),
    ];
  }
}

class PasswordRequirement {
  final String label;
  final bool isMet;
  
  PasswordRequirement({
    required this.label,
    required this.isMet,
  });
}
