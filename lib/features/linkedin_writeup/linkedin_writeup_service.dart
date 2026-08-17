import 'dart:typed_data';

import 'linkedin_writeup.dart';

typedef LinkedInWriteupAnalyzer = Future<LinkedInWriteup> Function({
  required String cvText,
  Uint8List? cvPdfBytes,
});

/// Placeholder used until the Worker's /linkedin-writeup endpoint is
/// deployed. Returns fixed sample content so the results screen can be
/// built and tested independently of the backend.
Future<LinkedInWriteup> mockGenerateLinkedInWriteup({
  required String cvText,
  Uint8List? cvPdfBytes,
}) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return const LinkedInWriteup(
    headline: 'Head of Security | 14+ Years Leadership | Ex-Indian Army',
    aboutSection:
        'Results-driven Senior Security & Operations Leader with 14 years of experience '
        'in high-stakes, complex environments — including crisis response, physical '
        'security, threat assessment, and large-team leadership. I have led 700+ '
        'personnel across multi-site, multi-stakeholder environments, managed risk '
        'registers, and built collaborative relationships with law enforcement and '
        'government authorities.\n\n'
        "I'm now transitioning from the Indian Army into corporate security and "
        'operations leadership roles, bringing a proven track record of operational '
        'discipline, crisis management, and stakeholder engagement to civilian '
        'organisations.',
    announcementPost:
        "After 14 years of service, I'm excited to share that I'm transitioning from "
        'the Indian Army into the corporate sector, focused on security operations and '
        'risk management leadership roles.\n\n'
        'Over my career, I have led teams of 700+ personnel, managed high-stakes '
        'security operations, and built strong stakeholder relationships across '
        'complex, multi-site environments.\n\n'
        "I'm actively exploring opportunities in security leadership, operations "
        'management, and risk management. If you know of a role or team that could '
        'use this experience, I would love to connect.',
  );
}
