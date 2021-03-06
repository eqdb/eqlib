// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/exceptions.dart';

void main() {
  final ctx = new SimpleExprContext();
  final rearrangeableIds = [ctx.operators.id('+'), ctx.operators.id('*')];

  test('Expr.functionIds', () {
    expect(
        ctx.parse('1 + a - b * c(d, e, f(g))').functionIds,
        equals('+-*abcdefg'
            .split('')
            .map((str) => ctx.assignId(str, false))
            .toSet()));
  });

  test('Expr.substituteAt', () {
    expect(() => ctx.parse('1').substituteAt(ctx.parseSubs('1 = 1/1'), 1),
        eqlibThrows('position not found'));

    expect(ctx.parse('a + b').substitute(ctx.parseSubs('b = c'), literal: true),
        equals(ctx.parse('a + c')));
    expect(
        () => ctx
            .parse('a + b')
            .substituteAt(ctx.parseSubs('?a = 1'), 1, literal: true),
        eqlibThrows('substitution does not match at the given position'));
    expect(
        ctx
            .parse('a + b')
            .substituteAt(ctx.parseSubs('?a = 1'), 1, literal: false),
        equals(ctx.parse('1 + b')));
  });

  test('Expr.rearrangeAt', () {
    // Exceptions
    expect(() => ctx.parse('1').rearrangeAt([1, 0], 1, rearrangeableIds),
        eqlibThrows('position not found'));
    expect(() => ctx.parse('1').rearrangeAt([1, 0], 0, rearrangeableIds),
        eqlibThrows('given position is not a rearrangeable function'));
    expect(() => ctx.parse('a').rearrangeAt([1, 0], 0, rearrangeableIds),
        eqlibThrows('given position is not a rearrangeable function'));
    expect(() => ctx.parse('a + b').rearrangeAt([2, 1], 0, rearrangeableIds),
        eqlibThrows('illegal value'));
    expect(() => ctx.parse('a + b').rearrangeAt([0], 0, rearrangeableIds),
        eqlibThrows('malformed format'));

    // Working behavior
    expect(ctx.parse('a + b').rearrangeAt([1, 0], 0, rearrangeableIds),
        equals(ctx.parse('b + a')));
    expect(
        ctx
            .parse('a * b * c * (d + e + f)')
            .rearrangeAt([2, 1, 0, -1], 6, rearrangeableIds).rearrangeAt(
                [1, 2, 3, 0, -1, -1], 0, rearrangeableIds),
        equals(ctx.parse('b * (c * ((f + (e + d)) * a))')));
  });
}
