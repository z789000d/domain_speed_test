1. 曾經在網頁使用過原生相機開發過 AR/VR 相關功能 (有處理過 Android 的, iOS 略知概念)。

---

## **iOS 平台：WKWebView 呼叫原生相機**

iOS 透過 **WKWebView** 實現網頁呼叫原生相機功能，主要依賴 **WKScriptMessageHandler** 協定。

### **JavaScript 呼叫原生相機：**

* **原生端準備 (Swift/Objective-C)：**
    你需要在 Swift 或 Objective-C 程式碼中，創建一個遵循 `WKScriptMessageHandler` 協定的類別（例如 `CameraHandler`），並將其實例註冊到 `WKWebView` 的 `userContentController` 中，給它一個名稱，比如 `"cameraHandler"`。

    ```swift
    // Swift 範例
    class CameraHandler: NSObject, WKScriptMessageHandler {
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "cameraHandler" {
                // 檢查 message.body，例如確認是 'takePhoto' 指令
                if let command = message.body as? String, command == "takePhoto" {
                    // 在這裡啟動原生相機介面 (例如使用 UIImagePickerController)
                    print("iOS: JavaScript 請求打開相機！")
                    // ... 實際啟動相機的程式碼 ...
                }
            }
        }
    }

    // 在 WKWebView 初始化時註冊
    let userContentController = WKUserContentController()
    userContentController.add(CameraHandler(), name: "cameraHandler")
    let config = WKWebViewConfiguration()
    config.userContentController = userContentController
    let webView = WKWebView(frame: .zero, configuration: config)
    ```

---

## **Android 平台：WebView 呼叫原生相機**

在 Android 上，透過 **WebView** 實現網頁呼叫原生相機功能，主要利用 `addJavascriptInterface()` 方法。

### **JavaScript 呼叫原生相機：**

* **原生端準備 (Kotlin/Java)：**
    你需要在 Kotlin 或 Java 程式碼中，創建一個普通物件（例如 `AndroidCameraBridge`），並在其中定義一個方法來處理相機請求。這個方法必須用 `@JavascriptInterface` 註解標記。然後，將這個物件透過 `addJavascriptInterface()` 方法注入到 `WebView` 的 JavaScript 環境中。

    ```kotlin
    // Kotlin 範例
    class AndroidCameraBridge(private val activity: Activity) {
        @JavascriptInterface // 必須添加此註解
        fun openCamera() {
            // 在這裡啟動原生相機介面 (例如使用 Intent(MediaStore.ACTION_IMAGE_CAPTURE))
            activity.runOnUiThread {
                println("Android: JavaScript 請求打開相機！")
                // ... 實際啟動相機的程式碼 ...
            }
        }
    }

    // 在 WebView 初始化時注入
    val webView = WebView(context)
    webView.settings.javaScriptEnabled = true // 啟用 JavaScript
    webView.addJavascriptInterface(AndroidCameraBridge(this), "AndroidCamera") // 'AndroidCamera' 是 JavaScript 中呼叫的介面名稱
    ```

* **網頁端 JavaScript：**
    當網頁需要啟動相機時，JavaScript 會透過 `window` 物件上對應的介面名稱來呼叫原生方法：

    ```javascript
    // JavaScript 範例
    function openCamera() {
        if (window.AndroidCamera) {
            window.AndroidCamera.openCamera(); // 呼叫原生端注入的 openCamera 方法
            console.log("JavaScript: 已發送 'openCamera' 請求到 Android 原生。");
        } else {
            console.log("JavaScript: 未檢測到 AndroidCamera 橋接。");
        }
    }
    // 例如，點擊按鈕時呼叫
    // <button onclick="openCamera()">開啟相機</button>
    ```

---

## **測速功能解析**

此測速功能主要透過 **`http` 套件**（一個輕量且直接的 HTTP 處理庫，可用 Dio 但 HTTP 提供了較少的封裝但更純粹的控制）來管理所有網路通訊。
透過 `stopwatch` 獲取api 回傳時間 如果異常 就給 infinity 並且用 異步 `Future` 去做背景同時呼叫  最後用`set`排序內容。
* [**main 應用程式入口**](lib/main.dart)：負責初始化並呼叫測速功能，是應用程式啟動測速流程的起點。
* [**資料模型 (data class)**](lib/domain_speed_data.dart)：定義了用於儲存每次網域測速結果的資料結構，包含網域資訊與下載時間。
* [**測速實際功能 (usecase)**](lib/use_case/domain_speed_use_case.dart)：
    * 核心的網路請求邏輯在 `_downloadImg` 方法中實現，用於對每個指定的網域進行連線和下載圖片（圖片內容不儲存）。
    * `execute` 方法則負責啟動批次的測速任務，它會將所有單一網域的下載請求作為 `Future` 異步執行，並在所有請求完成後，彙總測試時間。
    * 測試結果會被轉換成 `DomainSpeedData` 物件並儲存。
* [**測速驗證流程 (usecase)**](lib/use_case/get_speed_test_use_case.dart)：定義並協調整個測速流程，包括如何啟動測速、處理結果以及提供給應用程式其他部分使用。

---

##  萬物皆為Widget 以 StatefulWidget 與 StatelessWidget 為例子 

在沒有任何狀態管理套件（如 Provider, Bloc, Riverpod 等）的情況下，`StatefulWidget` 和 `StatelessWidget` 在 Flutter 應用程式中處理 UI 更新和內部資料的方式有以下幾個主要差異：

1.  **內部狀態與生命週期**：
    * **StatelessWidget**：**不包含任何內部狀態**，其配置（屬性）在建立時就確定且不可變。它沒有生命週期方法，只在 `build` 方法中描述 UI。
    * **StatefulWidget**：擁有一組可變的 `State` 物件，這個狀態可以隨著時間或使用者互動而改變。它提供了一系列**生命週期方法**（如 `initState()`, `dispose()` 等），允許開發者在不同階段執行邏輯，例如初始化資料或清理資源。

2.  **重建機制**：
    * **StatelessWidget**：一旦被建立，其 `build` 方法通常只會被呼叫一次，除非其父 Widget 重新構建並傳遞了新的參數。它**本身不會觸發重建**。
    * **StatefulWidget**：可以透過呼叫其 `State` 物件中的 `setState()` 方法來**觸發 UI 重新構建**。當 `setState()` 被呼叫時，Flutter 會重新運行 `build()` 方法，根據新的狀態值更新 UI。

3.  **適用性**：
    * **StatelessWidget**：適用於那些**不依賴於任何外部變化、使用者互動或時間流逝的靜態 UI 片段**。它們的內容一旦渲染就不會改變。
    * **StatefulWidget**：適用於**需要管理內部數據、響應使用者輸入、處理異步操作結果**（如 API 請求），或是需要動態更新 UI 的場景。

4.  **Widget** 只是一個不可變的顯示媒介，而它的**狀態和控制刷新**會在 **Element 層**處理，真正的**渲染**則會在 **RenderObject** 層進行。

---

## **程式碼問題解析**

你提供的這段 Flutter 程式碼中，`showDialog` 的呼叫位置是它最大的問題，會導致應用程式出現**有機率無限迭代**和**性能問題**。


### **主要問題 畫面被重建時：`showDialog` 在 `build` 方法中會被一直呼叫**

程式碼片段是放在一個 `build` 方法內：

```dart
Widget build(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const AlertDialog(
      title: Text('Alert Dialog')
    )
  ); 

  return const Center(
    child: Column(
      children: <Widget>[
        Text('Show Material Dialog'),
      ],
    ),
  );
}
```
---

## Flutter 事件處理流程詳解

在 Flutter 中，事件處理是一個從底層平台事件到應用程式 UI 更新的連續過程。以下是詳細的步驟拆解：

### 1. 事件發生與捕捉 

* **說明**：事件的生命週期始於作業系統層。當用戶執行諸如觸摸螢幕、按壓實體鍵或系統發出通知（例如應用程式生命週期狀態改變）等操作時，底層的平台（Android 或 iOS）會捕獲這些**原始事件**。
* **範例**：你輕觸螢幕，作業系統偵測到觸摸動作。

---

### 2. 轉換為 Flutter 指針事件與命中測試 (Hit Test) 

* **說明**：Flutter 引擎接收到原始事件後，會將其轉換為 Flutter 框架能理解的**指針事件 (Pointer Events)**。這些事件包括：
    * `PointerDownEvent`: 指針開始接觸螢幕。
    * `PointerMoveEvent`: 指針在螢幕上移動。
    * `PointerUpEvent`: 指針離開螢幕。
    * `PointerCancelEvent`: 指針事件被取消（例如，系統判斷為手勢衝突）。
* 這些指針事件會從 **Widget 樹的根部開始向下傳播**。這個過程稱為**(Hit Test)**。其目標是找出事件發生位置下方所有能夠響應事件的 **RenderObject**（Flutter 佈局和繪製的底層表示）。每個 `RenderObject` 會檢查其邊界是否包含事件座標；若包含，則將自身加入「命中測試結果列表」。
* **範例**：你的觸摸動作轉化為 `PointerDownEvent`，接著 Flutter 會從根 Widget 開始，遞歸檢查哪些 Widget 位於觸摸位置下方。


---

### 3. 轉換到 Flutter 可識別動作的 Widget (例如 `GestureDetector`) 

* **說明**：命中測試完成後，指針事件會分發給所有被命中的 **Widget**。通常，這些是專為處理用戶手勢而設計的 Widget，例如 `GestureDetector`。
* `GestureDetector` 是一個強大的 Widget，它包裹其他 Widget 並提供一系列回調（callbacks）來響應各種手勢，如 `onTap`、`onLongPress` 等。將指針事件傳遞給內部的手勢識別器。
* **範例**：你的觸摸動作穿透了 `Container`，最終抵達包裹在 `GestureDetector` 中的 `Text` Widget。

---

### 4. 由手勢識別器 (`GestureRecognizer`) 判斷具體動作 

* **說明**：當指針事件傳遞給 `GestureDetector` 時，它會將這些事件數據交給一個或多個**手勢識別器 (GestureRecognizer)**。`GestureRecognizer` 是 Flutter 框架提供的一系列演算法，它們會監聽指針事件流，並依據預定義的規則判斷具體的手勢。
* 常見的手勢識別器包括：
    * `TapGestureRecognizer`: 識別點擊事件。
    * `LongPressGestureRecognizer`: 識別長按事件。
    * `DoubleTapGestureRecognizer`: 識別雙擊事件。
    * `DragGestureRecognizer`: 識別拖動事件。
    * `ScaleGestureRecognizer`: 識別縮放事件。
* 若多個手勢識別器同時「爭奪」事件（例如，一個元素既可拖動又可點擊），Flutter 會運用**手勢競技場 (Gesture Arena)** 機制來解決衝突，確保最終只有一個手勢「獲勝」並處理該事件。
* **範例**：`GestureDetector` 內部的 `TapGestureRecognizer` 判斷你快速的按下和抬起動作符合「點擊」的條件。

---

### 5. 根據動作判斷是否更新 UI (狀態管理與重繪) 

* **說明**：一旦手勢識別器成功識別出特定動作（例如 `onTap`、`onLongPress`、`onDoubleTap`），相應的**回調函數**就會被觸發。在這些回調中，你會執行應用程式的**業務邏輯**，這通常會導致應用程式**狀態 (State)** 的變化。
* 對於 `StatefulWidget`，當狀態發生變化並需要更新 UI 時，你會調用 `setState()` 方法。`setState()` 會通知 Flutter 框架該 Widget 的狀態已更改，需要重新調用其 `build` 方法。

