int asInt(dynamic v) {
  if (v == null) {
    throw ArgumentError('Expected int, got null');
  }
  if (v is int) {
    return v;
  }
  if (v is num) {
    return v.toInt();
  }
  throw ArgumentError('Expected int, got ${v.runtimeType}');
}

int? asIntNullable(dynamic v) {
  if (v == null) {
    return null;
  }
  return asInt(v);
}

double asDouble(dynamic v) {
  if (v == null) {
    throw ArgumentError('Expected double, got null');
  }
  if (v is double) {
    return v;
  }
  if (v is num) {
    return v.toDouble();
  }
  throw ArgumentError('Expected double, got ${v.runtimeType}');
}

double? asDoubleNullable(dynamic v) {
  if (v == null) {
    return null;
  }
  return asDouble(v);
}

bool asBool(dynamic v) {
  if (v == null) {
    return false;
  }
  if (v is bool) {
    return v;
  }
  if (v is num) {
    return v != 0;
  }
  return false;
}
