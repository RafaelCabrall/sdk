// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library;

import 'dart:async' show EventSink, Future, Stream, StreamTransformer, Timer;

import 'dart:convert' show utf8;

import 'dart:io' show Process, ProcessSignal, Stdout;

import 'dart:io' as io show stderr, stdout;

import 'chain.dart' show Result;

import 'expectation.dart' show ExpectationSet;

class StdioProcess {
  final int exitCode;

  final String output;

  StdioProcess(this.exitCode, this.output);

  Result<int> toResult({int expected = 0}) {
    if (exitCode == expected) {
      return Result<int>.pass(exitCode);
    } else {
      return Result<int>(
          exitCode, ExpectationSet.defaultExpectations["RuntimeError"], output);
    }
  }

  static StreamTransformer<String, String> transformToStdio(Stdout stdio) {
    return StreamTransformer<String, String>.fromHandlers(
        handleData: (String data, EventSink<String> sink) {
      sink.add(data);
      stdio.write(data);
    });
  }

  static Future<StdioProcess> run(String executable, List<String> arguments,
      {String? input,
      Duration? timeout = const Duration(seconds: 60),
      bool suppressOutput = true,
      bool runInShell = false}) async {
    Process process =
        await Process.start(executable, arguments, runInShell: runInShell);
    Timer? timer;
    StringBuffer sb = StringBuffer();
    if (timeout != null) {
      timer = Timer(timeout, () {
        sb.write("Process timed out: ");
        sb.write(executable);
        sb.write(" ");
        sb.writeAll(arguments, " ");
        sb.writeln();
        sb.writeln("Sending SIGTERM to process");
        process.kill();
        timer = Timer(const Duration(seconds: 10), () {
          sb.writeln("Sending SIGKILL to process");
          process.kill(ProcessSignal.sigkill);
        });
      });
    }
    if (input != null) {
      process.stdin.write(input);
      await process.stdin.flush();
    }
    Future closeFuture = process.stdin.close();
    Stream stdoutStream = process.stdout.transform(utf8.decoder);
    Stream stderrStream = process.stderr.transform(utf8.decoder);
    if (!suppressOutput) {
      stdoutStream = stdoutStream.transform(transformToStdio(io.stdout));
      stderrStream = stderrStream.transform(transformToStdio(io.stderr));
    }
    Future<List<String>> stdoutFuture =
        stdoutStream.toList() as Future<List<String>>;
    Future<List<String>> stderrFuture =
        stderrStream.toList() as Future<List<String>>;
    int exitCode = await process.exitCode;
    timer?.cancel();
    sb.writeAll(await stdoutFuture);
    sb.writeAll(await stderrFuture);
    await closeFuture;
    return StdioProcess(exitCode, "$sb");
  }
}
