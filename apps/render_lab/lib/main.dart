import 'package:flutter/widgets.dart';

void main() => runApp(const RenderLab());

class RenderLab extends StatelessWidget {
  const RenderLab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xff172337),
        child: Center(
          child: Text(
            'FMDS Render Lab v0.1.0\nInfrastructure smoke test',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xffeeeeff), fontSize: 22),
          ),
        ),
      ),
    );
  }
}
