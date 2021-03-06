// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Mapping data.
class ExprMapping {
  /// When strict mode is enabled only some cases of generic internal remapping
  /// are allowed to prevent loopholes.
  /// Currently we offer no way to disable strict mode.
  static const strictMode = true;

  /// Map of from function ID to expression that is to be substituted.
  final Map<int, Expr> substitute;

  /// Map of from generic function ID to dependant variables.
  /// Used for remapping substituted generic function expressions.
  final Map<int, List<int>> dependantVars;

  ExprMapping([Map<int, Expr> substitute, Map<int, List<Expr>> dependantVars])
      : substitute = substitute ?? new Map<int, Expr>(),
        dependantVars = dependantVars ?? new Map<int, List<int>>();

  /// Add generic expression. Returns false if another expression is set.
  bool addExpression(int id, Expr targetExpr,
      [List<Expr> targetVars = const []]) {
    if (targetVars.isNotEmpty) {
      if (strictMode && targetVars.length > 1) {
        throw const EqLibException(
            'in strict mode multiple dependant variables are not allowed');
      }

      // Collect symbol IDs.
      final ids = new List<int>();
      for (final arg in targetVars) {
        if (arg is FunctionExpr && arg.isGeneric && arg.isSymbol) {
          ids.add(arg.id);
        } else {
          // Generic function arguments may only contain generic symbols.
          throw const EqLibException(
              'dependant variables must be generic symbols');
        }
      }

      if (dependantVars.containsKey(id)) {
        if (!const ListEquality().equals(dependantVars[id], ids)) {
          throw const EqLibException(
              'generic functions must have the same arguments');
        }
      } else {
        dependantVars[id] = ids;
      }
    }

    if (substitute.containsKey(id)) {
      return substitute[id] == targetExpr;
    } else {
      substitute[id] = targetExpr;
      return true;
    }
  }

  /// Get dependant variables for generic function ID.
  /// In this function we can also figure to which expression the dependant
  /// variable is mapped.
  List<int> getDependantVars(int fnId) {
    final depVars = dependantVars[fnId] ?? [];
    for (final varId in depVars) {
      // Check if a substitution expression is mapped already.
      if (!substitute.containsKey(varId)) {
        if (depVars.length == 1) {
          // Take the expression the generic function is mapped to, if this is a
          // function with one argument (e.g. sin(x)), map the variable to the
          // argument.
          final fn = substitute[fnId];
          if (fn is FunctionExpr && fn.arguments.length == 1) {
            substitute[varId] = fn.arguments.first;
          } else {
            throw const EqLibException('dependant variable cannot be inferred');
          }
        } else {
          throw const EqLibException('dependant variable cannot be inferred');
        }
      }
    }
    return depVars;
  }

  void finalize() {
    dependantVars.keys.forEach(getDependantVars);
  }
}
