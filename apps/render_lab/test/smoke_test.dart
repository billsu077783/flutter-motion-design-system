import 'package:flutter_test/flutter_test.dart';
import 'package:fmds_render_lab/main.dart';
void main(){test('parameter contract',(){expect(specs.length,28);for(final s in specs.values){expect(s[3],inInclusiveRange(s[0],s[1]));}expect(specs['edgeHighlight']![3],1.35);expect(specs['refractionDetail']![3],.25);expect(specs['mass']![3],1);expect(specs['stiffness']![3],180);expect(specs['damping']![3],12);});}
