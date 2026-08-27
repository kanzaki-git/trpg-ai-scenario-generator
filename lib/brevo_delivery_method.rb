class BrevoDeliveryMethod
  DEFAULT_SENDER_NAME = "TRPG AIシナリオ生成サービス".freeze

  def initialize(_settings); end

  def deliver!(mail)
    email = Brevo::SendSmtpEmail.new
    email.sender = {
      email: mail.from.first,
      name: sender_name(mail)
    }
    email.to = mail.to.map { |address| { email: address } }
    email.subject = mail.subject
    email.html_content = mail.html_part&.decoded
    email.text_content = mail.text_part&.decoded

    Brevo::TransactionalEmailsApi.new.send_transac_email(email)
  end

  private

  def sender_name(mail)
    display_name = mail[:from].display_names.first

    display_name.nil? || display_name.empty? ? DEFAULT_SENDER_NAME : display_name
  end
end
