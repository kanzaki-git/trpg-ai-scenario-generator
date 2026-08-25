require "test_helper"

class ErrorPagesTest < ActiveSupport::TestCase
  EXPECTED_MESSAGES = {
    "400" => "リクエストを処理できませんでした",
    "404" => "お探しのページが見つかりません",
    "406-unsupported-browser" => "このブラウザは利用できません",
    "422" => "操作を処理できませんでした",
    "500" => "一時的なエラーが発生しました"
  }.freeze

  test "エラーページの言語が日本語に設定されている" do
    EXPECTED_MESSAGES.each_key do |status|
      assert_includes error_page(status), '<html lang="ja">'
    end
  end

  test "エラーの内容が分かりやすく表示されている" do
    EXPECTED_MESSAGES.each do |status, message|
      assert_includes error_page(status), message
    end
  end

  test "トップページへ戻る案内が表示されている" do
    EXPECTED_MESSAGES.each_key do |status|
      html = error_page(status)

      assert_includes html, "トップページへ戻る"
      assert_includes html, 'href="/"'
    end
  end

  test "開発者向けの内部情報が表示されていない" do
    EXPECTED_MESSAGES.each_key do |status|
      html = error_page(status)

      refute_match(
        /application owner|check the logs|stack trace|api[_ ]?key/i,
        html
      )
    end
  end

  private

  def error_page(status)
    Rails.root.join("public/#{status}.html").read
  end
end
