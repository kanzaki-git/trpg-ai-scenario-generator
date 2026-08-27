require "test_helper"

class BrevoDeliveryMethodTest < ActiveSupport::TestCase
  test "Action MailerのメールをBrevo用データへ変換する" do
    mail = Mail.new do
      from "from@example.com"
      to "to@example.com"
      subject "テストメール"

      text_part do
        body "テキスト本文"
      end

      html_part do
        content_type "text/html; charset=UTF-8"
        body "<p>HTML本文</p>"
      end
    end

    sent_email = nil
    api_client = Object.new
    api_client.define_singleton_method(:send_transac_email) do |email|
      sent_email = email
    end

    Brevo::TransactionalEmailsApi.stub(:new, api_client) do
      BrevoDeliveryMethod.new({}).deliver!(mail)
    end

    assert_equal(
      {
        email: "from@example.com",
        name: "TRPG AIシナリオ生成サービス"
      },
      sent_email.sender
    )
    assert_equal [ { email: "to@example.com" } ], sent_email.to
    assert_equal "テストメール", sent_email.subject
    assert_equal "テキスト本文", sent_email.text_content
    assert_equal "<p>HTML本文</p>", sent_email.html_content
  end
end
