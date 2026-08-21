# Fat Controller・Fat Model調査結果

## 調査目的

ControllerやModelに処理が集中していないか確認し、責務を分割する必要がある箇所と改善方針を整理する。

## 調査対象

主に次のファイルを調査した。

- `app/controllers/scenarios_controller.rb`
- `app/models/scenario_generation_log.rb`
- `app/models/user.rb`
- `app/models/scenario.rb`
- `app/services/scenario_generator.rb`
- `app/services/scenario_generation_saver.rb`

## コード行数

| ファイル | 行数 |
|---|---:|
| `app/services/scenario_generator.rb` | 512 |
| `app/controllers/scenarios_controller.rb` | 258 |
| `app/models/scenario_generation_log.rb` | 178 |
| `app/services/scenario_generation_saver.rb` | 172 |
| `app/models/user.rb` | 45 |
| `app/models/scenario.rb` | 25 |

行数だけでFat Controller・Fat Modelとは判断せず、1つのクラスが担当している責務の種類も確認した。

## 調査結果

### ScenariosController

#### 判定

Fat Controllerに該当する。

特に、`create`と`generation_status`にシナリオ生成に関する処理が集中している。

#### createが担当している処理

- Scenarioの組み立てと入力内容の検証
- 生成回数の予約
- 二重生成の確認
- 生成上限の確認
- 生成ログの作成
- OpenAI APIによるバックグラウンド生成の開始
- OpenAIレスポンスIDの保存
- APIエラーの記録
- 失敗したScenarioの削除
- 失敗時の生成回数返却
- リダイレクトまたは画面の再表示

ControllerがHTTPレスポンスの決定だけでなく、生成開始から失敗時の後処理まで担当している。

#### generation_statusが担当している処理

- OpenAI APIから生成状況を取得
- OpenAIのステータスをログへ出力
- 生成状況による処理の分岐
- 生成結果の保存
- Scenarioを完了状態へ変更
- 生成ログへの完了情報の記録
- 失敗内容の記録
- Scenarioを失敗状態へ変更
- 失敗時の生成回数返却
- JSONレスポンスの作成

`complete_background_generation`と`fail_background_generation`はprivateメソッドだが、生成成功・失敗時の重要な業務処理を担当している。

privateメソッドへ分けても、Controllerがその責務を持っていることは変わらない。

#### 改善方針

次の処理をService Objectへ分割する。

- シナリオ生成開始処理
- 生成状況の更新処理
- 生成成功時の完了処理
- 生成失敗時の後処理

Controllerには、主に次の処理を残す。

- リクエストパラメータの受け取り
- Service Objectの呼び出し
- リダイレクト、画面表示、JSONなどのレスポンス決定

### ScenarioGenerationLog

#### 判定

明確なFat Modelとは判断しないが、一部に分割候補がある。

関連付け、状態管理、バリデーション、生成成功・失敗の記録は、生成ログ自身に関する責務としてまとまっている。

一方で、次の処理は別の責務として分割を検討できる。

- OpenAIレスポンスからトークン使用量を抽出する処理
- トークン使用量と単価から推定料金を計算する処理

#### 改善方針

必要になった場合は、次のようなクラスへの分割を検討する。

- `ScenarioGenerationUsageExtractor`
- `ScenarioGenerationCostCalculator`

ただし、現時点では処理が生成ログに関係する範囲にまとまっているため、優先度は低い。

### User

#### 判定

Fat Modelには該当しない。

認証、関連付け、バリデーション、シナリオ生成回数の管理を担当している。

`reserve_scenario_generation!`はScenarioも保存しているが、次の処理を1つの業務ルールとしてまとめている。

- 二重生成を防止する
- 生成回数の上限を確認する
- Scenarioを生成中にする
- 生成回数を増やす

`with_lock`によって同じユーザーからの同時リクエストを一件ずつ処理し、生成回数の整合性を守っている。

そのため、現時点では分割しない。

### Scenario

#### 判定

Fat Modelには該当しない。

関連付け、生成状態、入力項目のバリデーションのみを担当している。

関連付けは複数あるが、すべてシナリオを構成するデータとの関係を表しているため、責務は集中していない。

### ScenarioGenerator

#### 判定

Fat Controller・Fat Modelではないが、複数の責務を担当している。

512行のうち、約384行はOpenAIへ渡すプロンプトである。

それ以外に、次の処理も担当している。

- OpenAI APIとの通信
- バックグラウンド生成状況の取得
- OpenAIレスポンスからJSONを抽出
- JSONをSchemaオブジェクトへ変換
- 通常レスポンスから構造化結果を抽出

#### 改善方針

まず、プロンプト作成処理を次のようなクラスへ分割することを検討する。

- `ScenarioGenerationPrompt`

必要になった場合は、レスポンス解析処理も次のようなクラスへ分割する。

- `ScenarioGenerationResponseParser`

### ScenarioGenerationSaver

#### 判定

処理を分割する必要はない。

172行あるが、すべてのメソッドが、OpenAIの生成結果を関連するテーブルへ保存するという1つの責務にまとまっている。

また、すべての保存を同じトランザクション内で行うことで、途中でエラーが発生した場合に中途半端なデータが残ることを防いでいる。

## 改善対象の優先順位

### 優先度：高

1. `ScenariosController#create`の生成開始処理をService Objectへ分割する
2. `ScenariosController#generation_status`の生成状況更新処理をService Objectへ分割する
3. 生成成功・失敗時の業務処理をControllerから分離する

### 優先度：中

1. `ScenarioGenerator#prompt`を専用クラスへ分割する
2. OpenAIレスポンスの解析処理を専用クラスへ分割する

### 優先度：低

1. `ScenarioGenerationLog`の使用量抽出処理を分割する
2. `ScenarioGenerationLog`の料金計算処理を分割する

## 結論

最も優先して改善する対象は`ScenariosController`である。

特に、シナリオ生成の開始、生成状況の更新、生成成功時の保存、生成失敗時の後処理がControllerへ集中している。

Modelについては、現時点で明確なFat Modelは確認されなかった。

`ScenarioGenerationLog`には分割候補があるが、まずは`ScenariosController`の責務をService Objectへ移すことを優先する。

実際のリファクタリングは、調査とは別のIssueで行う。
