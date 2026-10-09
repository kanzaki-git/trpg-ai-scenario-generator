require "test_helper"

class ScenarioShareTest < ActiveSupport::TestCase
  test "共有設定を保存すると共有トークンが自動生成される" do
    scenario_shares(:two).destroy!

    share = ScenarioShare.create!(
      scenario: scenarios(:two),
      public_title: "公開用タイトル",
      public_description: "ネタバレを含まない公開用の紹介文です。"
    )

    assert_predicate share.share_token, :present?
    assert_operator share.share_token.length, :>=, 24
  end

  test "公開用タイトルは必須" do
    share = scenario_shares(:one)
    share.public_title = nil

    assert_not share.valid?
    assert_predicate share.errors[:public_title], :present?
  end

  test "公開用タイトルは100文字以内" do
    share = scenario_shares(:one)
    share.public_title = "あ" * 101

    assert_not share.valid?
    assert_predicate share.errors[:public_title], :present?
  end

  test "公開用紹介文は必須" do
    share = scenario_shares(:one)
    share.public_description = nil

    assert_not share.valid?
    assert_predicate share.errors[:public_description], :present?
  end

  test "公開用紹介文は500文字以内" do
    share = scenario_shares(:one)
    share.public_description = "あ" * 501

    assert_not share.valid?
    assert_predicate share.errors[:public_description], :present?
  end

  test "同じシナリオに共有設定を重複して作成できない" do
    duplicate_share = ScenarioShare.new(
      scenario: scenarios(:one),
      public_title: "別の公開用タイトル",
      public_description: "別の公開用紹介文です。"
    )

    assert_not duplicate_share.valid?
    assert_predicate duplicate_share.errors[:scenario_id], :present?
  end

  test "公開を開始できる" do
    share = scenario_shares(:two)

    assert_not share.published?

    share.publish!

    assert share.published?
    assert_predicate share.published_at, :present?
  end

  test "公開を停止できる" do
    share = scenario_shares(:one)

    assert share.published?

    share.unpublish!

    assert_not share.published?
    assert_nil share.published_at
  end

  test "シナリオを削除すると共有設定も削除される" do
    scenario = scenarios(:one)

    assert_difference "ScenarioShare.count", -1 do
      scenario.destroy!
    end
  end
end
