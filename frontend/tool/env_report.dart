import 'dart:convert';
import 'dart:io';

Future<String> runCmd(List<String> cmd, {String? cwd}) async {
  ProcessResult pr;
  if (Platform.isWindows) {
    final joined = cmd.map((a) => a.contains(' ') ? '"$a"' : a).join(' ');
    pr = await Process.run(
      'cmd',
      ['/c', 'chcp 65001>nul & $joined'],
      workingDirectory: cwd,
      stdoutEncoding: null,
      stderrEncoding: null,
      runInShell: false,
    );
  } else {
    pr = await Process.run(
      cmd.first,
      cmd.sublist(1),
      workingDirectory: cwd,
      stdoutEncoding: null,
      stderrEncoding: null,
      runInShell: true,
    );
  }
  final bytes = <int>[];
  if (pr.stdout is List<int>) bytes.addAll(pr.stdout as List<int>);
  if (pr.stderr is List<int>) bytes.addAll(pr.stderr as List<int>);
  return decodeBest(bytes);
}

String decodeBest(List<int> b) {
  try {
    return utf8.decode(b);
  } catch (_) {
    try {
      return systemEncoding.decode(b);
    } catch (_) {
      return utf8.decode(b, allowMalformed: true);
    }
  }
}

String ts() {
  final d = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}${two(d.month)}${two(d.day)}_${two(d.hour)}${two(d.minute)}${two(d.second)}';
}

String readIfExists(String path) {
  final f = File(path);
  if (!f.existsSync()) return '';
  try {
    return f.readAsStringSync(encoding: utf8);
  } catch (_) {
    try {
      return f.readAsStringSync(encoding: systemEncoding);
    } catch (_) {
      return f.readAsStringSync();
    }
  }
}

List<String> findLines(String path, RegExp re) {
  final f = File(path);
  if (!f.existsSync()) return [];
  late List<String> lines;
  try {
    lines = f.readAsLinesSync(encoding: utf8);
  } catch (_) {
    try {
      lines = f.readAsLinesSync(encoding: systemEncoding);
    } catch (_) {
      lines = f.readAsLinesSync();
    }
  }
  return lines.where((l) => re.hasMatch(l)).toList();
}

Future<void> main() async {
  final outPath = 'env_report_${ts()}.md';
  final sink = File(outPath).openWrite(encoding: utf8);
  sink.write('\uFEFF');

  sink.writeln('# Flutter');
  sink.writeln(await runCmd(['flutter', '--version']));
  sink.writeln(await runCmd(['flutter', 'doctor', '-v']));
  sink.writeln(await runCmd(['dart', '--version']));

  sink.writeln('# Java');
  sink.writeln(await runCmd(['java', '-version']));

  sink.writeln('# Env');
  sink.writeln('ANDROID_HOME=${Platform.environment['ANDROID_HOME'] ?? ''}');
  sink.writeln('ANDROID_SDK_ROOT=${Platform.environment['ANDROID_SDK_ROOT'] ?? ''}');
  sink.writeln('JAVA_HOME=${Platform.environment['JAVA_HOME'] ?? ''}');

  sink.writeln('# Git');
  sink.writeln((await runCmd(['git', 'rev-parse', '--short', 'HEAD'])).trim());

  sink.writeln('# Android/Gradle');
  final androidDir = Directory('android');
  if (androidDir.existsSync()) {
    final gradlew = Platform.isWindows ? 'gradlew.bat' : './gradlew';
    sink.writeln(await runCmd([gradlew, '-v'], cwd: 'android'));
    sink.writeln('## gradle-wrapper.properties');
    sink.writeln(readIfExists('android/gradle/wrapper/gradle-wrapper.properties'));
    sink.writeln('## local.properties');
    sink.writeln(readIfExists('android/local.properties'));
    sink.writeln('## SDK numbers');
    final re = RegExp(r'(compileSdk|targetSdk|minSdk|ndkVersion)');
    final candidates = [
      'android/app/build.gradle',
      'android/app/build.gradle.kts',
      'android/build.gradle',
      'android/build.gradle.kts'
    ];
    for (final p in candidates) {
      final lines = findLines(p, re);
      if (lines.isNotEmpty) {
        sink.writeln('### $p');
        for (final l in lines) sink.writeln(l);
      }
    }
  }

  sink.writeln('# sdkmanager --list (top)');
  try {
    final list = await runCmd(['sdkmanager', '--list']);
    sink.writeln(list.split('\n').take(200).join('\n'));
  } catch (_) {}

  await sink.flush();
  await sink.close();
  stdout.writeln(outPath);
}
