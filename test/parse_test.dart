// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:eqlib/eqlib.dart';
import 'package:eqlib/inline.dart';

/// Even shorter alias for convenience.
Expr n(num val) => number(val);

void main() {
  test('Fundamental checks for the parser', () {
    final a = generic('a'), b = generic('b'), c = generic('c');

    // Extra parentheses
    expect(new Expr.parse('(((?a + ?b)))'), equals(a + b));

    // Precedence and whitespaces
    expect(new Expr.parse(' ( 1 + 2 ) * 3 ^ sin( a + ?b ) '),
        equals((n(1) + 2) * (n(3) ^ fn1('sin')(symbol('a') + b))));

    // Nested functions and whitespaces
    expect(new Eq.parse(' mul  ( mul(  ?a, ?b), ?c)=  mul(?a,mul(?b,   ?c))  '),
        equals(eq((a * b) * c, a * (b * c))));

    // Numeric values
    expect(new Expr.parse('-1.23 - 4 + .567 ^ -.89'),
        equals((n(-1.23) - 4) + (n(.567) ^ -.89)));
    expect(
        (new Expr.parse('-1.23 - 4 + .567 ^ -.89').evaluate() * 1000).toInt(),
        equals(-3573));

    // Unary minus
    expect(new Expr.parse('-  - -1').evaluate(), equals(-1));
    expect(new Expr.parse('---?a'), equals(-(-(-a))));
    expect(new Expr.parse('-?a ^ ?b'), equals((-a) ^ b));

    // Implicit multiplication
    expect(new Expr.parse('?a^?b?c'), equals(a ^ (b * c)));
    expect(new Expr.parse('?a^f(?b)?c'), equals(a ^ (fn1('f')(b)) * c));
    expect(new Expr.parse('?a ?b ?c'), equals(a * (b * c)));
    expect(new Expr.parse('(?a ?b) ?c'), equals((a * b) * c));
    expect(new Expr.parse('?a sin(?b)'), equals(a * fn1('sin')(b)));
    expect(new Expr.parse('-1 2 ^ -3 4'), equals(n(-1) * (n(2) ^ (n(-3) * 4))));
    expect(new Expr.parse('-3sin(2 ^3 (4+5)?b)'),
        equals(n(-3) * fn1('sin')(n(2) ^ (n(3) * ((n(4) + 5) * b)))));
  });

  test('Parentheses mismatch', () {
    expect(() => new Expr.parse(''), throwsFormatException);
    expect(() => new Expr.parse(')'), throwsFormatException);
    expect(() => new Expr.parse('a+b)'), throwsFormatException);
    expect(() => new Expr.parse('fn(,)'), throwsFormatException);
    expect(() => new Expr.parse('a,b'), throwsFormatException);
    expect(() => new Expr.parse('a+b,b'), throwsFormatException);
    expect(() => new Expr.parse('(a,b)'), throwsFormatException);
    expect(() => new Expr.parse('a+'), throwsFormatException);
  });

  test('Derivation of centripetal acceleration (step 1)', () {
    final pvec = new Eq.parse('pvec = vec2d');
    pvec.substitute(new Eq.parse('vec2d = add(mul(x, ihat), mul(y, jhat))'));
    pvec.substitute(new Eq.parse('x = px'));
    pvec.substitute(new Eq.parse('y = py'));
    pvec.substitute(new Eq.parse('px = mul(r, sin(theta))'));
    pvec.substitute(new Eq.parse('py = mul(r, cos(theta))'));
    pvec.substitute(
        new Eq.parse('mul(mul(?a, ?b), ?c) = mul(?a, mul(?b, ?c))'));
    pvec.substitute(
        new Eq.parse('mul(mul(?a, ?b), ?c) = mul(?a, mul(?b, ?c))'));
    pvec.substitute(
        new Eq.parse('add(mul(?a, ?b), mul(?a, ?c)) = mul(?a, add(?b, ?c))'));

    eqlibSABackend.printerOpChars = true;
    expect(pvec.toString(),
        equals('pvec={r}*{{sin(theta)}*{ihat} + {cos(theta)}*{jhat}}'));
    eqlibSABackend.printerOpChars = false;
  });

  test('Solve a simple equation', () {
    final eq = new Eq.parse('add(mul(x, 2), 5) = 9');
    eq.envelop(new Expr.parse('add(?a, ?b)'), new Expr.parse('sub({}, ?b)'));
    eq.substitute(new Eq.parse('sub(add(?a, ?b), ?b) = ?a'));
    eq.envelop(new Expr.parse('mul(?a, ?b)'), new Expr.parse('div({}, ?b)'));
    eq.substitute(new Eq.parse('div(mul(?a, ?b), ?b) = ?a'));
    eq.evaluate();

    expect(eq.left, equals(symbol('x')));
    expect(eq.right.evaluate(), equals(2.0));
  });
}
