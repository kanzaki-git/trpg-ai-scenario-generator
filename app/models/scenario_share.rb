class ScenarioShare < ApplicationRecord
  has_secure_token :share_token

  belongs_to :scenario
  scope :published, -> { where.not(published_at: nil) }

  validates :scenario_id, uniqueness: true
  validates :share_token, presence: true, uniqueness: true

  validates :public_title,
            presence: true,
            length: { maximum: 100 }

  validates :public_description,
            presence: true,
            length: { maximum: 500 }

  def published?
    published_at.present?
  end

  def publish!
    update!(published_at: Time.current)
  end

  def unpublish!
    update!(published_at: nil)
  end
end
