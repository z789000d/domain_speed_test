import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/domain_speed_data.dart';
import 'package:http/io_client.dart';

class DomainSpeedUseCase {
  static const String _imagePath = '/test-img';
  List<DomainSpeedData> _results = [];

  static final DomainSpeedUseCase _instance = DomainSpeedUseCase._internal();

  factory DomainSpeedUseCase() {
    return _instance;
  }

  DomainSpeedUseCase._internal() {
    createInsecureHttpClient();
  }

  http.Client createInsecureHttpClient() {
    HttpClient httpClient =
        HttpClient()
          ..badCertificateCallback =
              ((X509Certificate cert, String host, int port) => true);
    return IOClient(httpClient);
  }

  /// 請求圖片並回傳下載時間 (毫秒)。
  /// 請求會背景執行，圖片內容不會被儲存。
  /// 如果下載失敗或超時，會回傳 [double.infinity] 表示極長時間。
  Future<double> _downloadImg({required String domain}) async {
    final uri = Uri.parse('https://$domain');

    final Stopwatch stopwatch = Stopwatch();
    stopwatch.start();

    try {
      final completer = Completer<double>();

      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      stopwatch.stop();

      if (response.statusCode == HttpStatus.ok) {
        completer.complete(stopwatch.elapsedMilliseconds.toDouble());
      } else {
        print('Error downloading $domain: HTTP Status ${response.statusCode}');
        completer.complete(double.infinity);
      }
      return completer.future;
    } on TimeoutException {
      stopwatch.stop();
      print('Timeout downloading $domain');
      return double.infinity;
    } on SocketException catch (e) {
      stopwatch.stop();
      print('Network error downloading $domain: ${e.message}');
      return double.infinity;
    } catch (e) {
      stopwatch.stop();
      print('Unknown error downloading $domain: $e');
      return double.infinity;
    }
  }

  /// 儲存測速結果。
  /// 傳入參數為一個 [List<DomainSpeedResult>]，儲存前會依據下載時間由小到大排序。
  void _set({required List<DomainSpeedData> results}) {
    // 複製一份列表以避免直接修改傳入的列表
    _results = List.from(results);
    // 依據下載時間排序 (從小到大)
    _results.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    print('Results set and sorted: $_results');
  }

  /// 取得當前儲存的測速結果列表。
  /// 返回一個包含 [DomainSpeedResult] 物件的列表，這些物件已按下載時間排序。
  List<DomainSpeedData> getResults() {
    return List.from(_results);
  }

  /// 方便測試或展示，將結果列表轉換為 JSON 字串
  String getResultsAsJson() {
    return jsonEncode(_results.map((r) => r.toJson()).toList());
  }

  /// 模擬背景執行所有網域的測速並儲存結果
  ///
  /// [domains] 是一個要測速的網域列表。
  /// 如果 `clearBeforeTest` 為 true，則會在測速前清空現有結果。
  Future<void> execute(
    List<String> domains, {
    bool clearBeforeTest = true,
  }) async {
    if (clearBeforeTest) {
      _results.clear(); // 清空之前的結果
    }

    final List<DomainSpeedData> newResults = [];
    final List<Future<void>> testFutures = []; // 用於等待所有測速完成

    for (final domain in domains) {
      testFutures.add(() async {
        print('Starting test for $domain...');
        final time = await _downloadImg(domain: domain);
        newResults.add(DomainSpeedData(domain: domain, timeMs: time));
        print('Finished test for $domain. Time: ${time}ms');
      }());
    }

    await Future.wait(testFutures);

    _set(results: newResults);
    print('All domain speed tests completed and results saved.');
  }
}
