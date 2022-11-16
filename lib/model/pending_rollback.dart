class PendingRollback{
  final String key;
  dynamic oriValue;
  dynamic toValue;

  PendingRollback({required this.key, this.oriValue, this.toValue});
}