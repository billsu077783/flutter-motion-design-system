import 'dart:js_interop';
import 'dart:ui_web' as web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as dom;
dom.HTMLIFrameElement? frame;
Map<String,dynamic> latest = {};
bool registered = false;
void send() { frame?.contentWindow?.postMessage(latest.jsify(), dom.window.location.origin.toJS); }
Widget referenceView(Map<String,dynamic> state) {
 latest = state;
 if (!registered) {
 registered = true;
 web.platformViewRegistry.registerViewFactory('fmds-reference', (int id) {
 final el = dom.HTMLIFrameElement()..src='d2-d4-reference.html'..style.border='0'..style.width='100%'..style.height='100%';
 frame=el;
 el.addEventListener('load', ((dom.Event e) {send();}).toJS);
 return el;
 });
 }
 send();
 return const HtmlElementView(viewType:'fmds-reference');
}