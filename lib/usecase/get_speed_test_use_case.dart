import 'package:domain_speed_test/usecase/domain_speed_use_case.dart';

class GetSpeedTestUseCase {
  Future<void> execute() async {
    final domainSpeedUseCase = DomainSpeedUseCase();

    final domainsToTest = [
      "www.runoob.com/wp-content/uploads/2013/11/icon128x128.png",
      "www.runoob.com/wp-content/uploads/2013/11/icon128x128.png",
      "www.runoob.com/wp-content/uploads/2013/11/icon128x128.png",
    ]; //測試用網域

    print('--- 開始執行網域測速 ---');
    await domainSpeedUseCase.execute(domainsToTest);
    print('--- 網域測速完成 ---');
    final sortedResults = domainSpeedUseCase.getResults();
    print('排序後的結果:');
    for (var result in sortedResults) {
      print(result);
    }
    print('\nJSON 格式的結果:');
    print(domainSpeedUseCase.getResultsAsJson());
  }
}
