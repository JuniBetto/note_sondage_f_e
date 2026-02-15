/*extension StringExtensions on String {
  String toCamelCase() {
    List<String> words = split(' '); // Divide la stringa in parole
    return words.first.toLowerCase() +
        words
            .skip(1)
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join('');
  }
}*/
