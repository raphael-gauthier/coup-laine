import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> callPhone(BuildContext context, String phone) async {
  final cleaned = phone.replaceAll(RegExp(r'\s'), '');
  final uri = Uri(scheme: 'tel', path: cleaned);
  if (!await launchUrl(uri) && context.mounted) {
    showFToast(
      context: context,
      title: const Text("Impossible de lancer l'appel"),
    );
  }
}

Future<void> sendSms(BuildContext context, String phone) async {
  final cleaned = phone.replaceAll(RegExp(r'\s'), '');
  final uri = Uri(scheme: 'sms', path: cleaned);
  if (!await launchUrl(uri) && context.mounted) {
    showFToast(
      context: context,
      title: const Text("Impossible de lancer l'app SMS"),
    );
  }
}
