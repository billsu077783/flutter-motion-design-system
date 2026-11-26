import 'package:flutter_test/flutter_test.dart';
import 'package:fmds_render_lab/main.dart';
void main(){test('parameter contract',(){expect(specs.length,23);expect(specs['mass']![3],1);expect(specs['stiffness']![3],180);expect(specs['damping']![3],12);});}
