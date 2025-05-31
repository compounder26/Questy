/// Utility extensions for String class
extension StringExtension on String {
  /// Capitalizes the first letter of a string and makes the rest lowercase
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
