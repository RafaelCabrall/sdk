// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:logging/logging.dart';

import 'driver.dart';
import 'input_converter.dart';

/// An [Operation] represents an action such as sending a request to the server.
abstract class Operation {
  Future<void>? perform(Driver driver);
}

/// A [RequestOperation] sends a JSON request to the server.
class RequestOperation extends Operation {
  final CommonInputConverter converter;
  final Map<String, dynamic> json;

  RequestOperation(this.converter, this.json);

  @override
  Future<void>? perform(Driver driver) {
    var stopwatch = Stopwatch();
    var originalId = json['id'] as String;
    var method = json['method'] as String;
    json['clientRequestTime'] = DateTime.now().millisecondsSinceEpoch;
    driver.logger.log(Level.FINE, 'Sending request: $method\n  $json');
    stopwatch.start();

    void recordResult(bool success, result) {
      var elapsed = stopwatch.elapsed;
      driver.results.record(method, elapsed, success: success);
      driver.logger.log(
        Level.FINE,
        'Response received: $method : $elapsed\n  $result',
      );
    }

    driver
        .send(method, converter.asMap(json['params']))
        .then((result) {
          recordResult(true, result);
          processResult(originalId, result!, stopwatch);
        })
        .catchError((exception) {
          recordResult(false, exception);
          converter.processErrorResponse(originalId, exception);
        });
    return null;
  }

  void processResult(
    String id,
    Map<String, Object?> result,
    Stopwatch stopwatch,
  ) {
    converter.processResponseResult(id, result);
  }
}

/// A [ResponseOperation] waits for a JSON response from the server.
class ResponseOperation extends Operation {
  static final Duration responseTimeout = Duration(seconds: 60);
  final CommonInputConverter converter;
  final Map<String, Object?> requestJson;
  final Map<String, Object?> responseJson;
  final Completer<void> completer = Completer();
  late Driver driver;

  ResponseOperation(this.converter, this.requestJson, this.responseJson) {
    completer.future.then(_processResult).timeout(responseTimeout);
  }

  @override
  Future<void>? perform(Driver driver) {
    this.driver = driver;
    var id = responseJson['id'] as String;
    return converter.processExpectedResponse(id, completer);
  }

  bool _equal(Object? expectedResult, Object? actualResult) {
    if (expectedResult is Map && actualResult is Map) {
      if (expectedResult.length == actualResult.length) {
        return expectedResult.keys.every((key) {
          return key ==
                  'fileStamp' || // fileStamp values will not be the same across runs
              _equal(expectedResult[key], actualResult[key]);
        });
      }
    } else if (expectedResult is List && actualResult is List) {
      if (expectedResult.length == actualResult.length) {
        for (var i = 0; i < expectedResult.length; ++i) {
          if (!_equal(expectedResult[i], actualResult[i])) {
            return false;
          }
        }
        return true;
      }
    }
    return expectedResult == actualResult;
  }

  /// Compare the expected and actual server response result.
  void _processResult(Object? actualResult) {
    var expectedResult = responseJson['result'];
    if (!_equal(expectedResult, actualResult)) {
      var expectedError = responseJson['error'];
      String format(value) {
        var text = '\n$value';
        if (text.endsWith('\n')) {
          text = text.substring(0, text.length - 1);
        }
        return text.replaceAll('\n', '\n  ');
      }

      var message =
          'Request:${format(requestJson)}\n'
          'expected result:${format(expectedResult)}\n'
          'expected error:${format(expectedError)}\n'
          'but received:${format(actualResult)}';
      var method = requestJson['method'] as String;
      driver.results.recordUnexpectedResults(method);
      converter.logOverlayContent();
      if (expectedError == null) {
        converter.logger.log(Level.SEVERE, message);
      } else {
        throw message;
      }
    }
  }
}

class StartServerOperation extends Operation {
  @override
  Future<void> perform(Driver driver) {
    return driver.startServer();
  }
}

class WaitForAnalysisCompleteOperation extends Operation {
  @override
  Future<void> perform(Driver driver) {
    var start = DateTime.now();
    driver.logger.log(Level.FINE, 'waiting for analysis to complete');
    late StreamSubscription<ServerStatusParams> subscription;
    late Timer timer;
    var completer = Completer();
    var isAnalyzing = false;
    subscription = driver.onServerStatus.listen((ServerStatusParams params) {
      var analysisStatus = params.analysis;
      if (analysisStatus != null) {
        if (analysisStatus.isAnalyzing) {
          isAnalyzing = true;
        } else {
          subscription.cancel();
          timer.cancel();
          var end = DateTime.now();
          var delta = end.difference(start);
          driver.logger.log(Level.FINE, 'analysis complete after $delta');
          completer.complete();
          driver.results.record('analysis complete', delta, notification: true);
        }
      }
    });
    timer = Timer.periodic(Duration(milliseconds: 20), (_) {
      if (!isAnalyzing) {
        // TODO(danrubel): revisit this once source change requests are implemented
        subscription.cancel();
        timer.cancel();
        driver.logger.log(Level.INFO, 'analysis never started');
        completer.complete();
        return;
      }
      // Timeout if no communication received within the last 60 seconds.
      var currentTime = driver.server.currentElapseTime;
      var lastTime = driver.server.lastCommunicationTime!;
      if (currentTime - lastTime > 60) {
        subscription.cancel();
        timer.cancel();
        var message = 'gave up waiting for analysis to complete';
        driver.logger.log(Level.WARNING, message);
        completer.completeError(message);
      }
    });
    return completer.future;
  }
}
