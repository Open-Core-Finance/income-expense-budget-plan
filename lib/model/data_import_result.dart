class DataImportResult {
  String dataLabel;
  int countSuccess = 0;
  int countError = 0;
  int countSkipped = 0;
  int countOverride = 0;
  DataImportResult({required this.dataLabel});
}
