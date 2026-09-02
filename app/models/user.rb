class User < ApplicationRecord
  authenticates_with_sorcery!

  has_many :scenarios, dependent: :destroy
  has_many :scenario_generation_logs, dependent: :destroy

  SCENARIO_GENERATION_LIMIT = 3

  def scenario_generation_available?
    scenario_generation_count < SCENARIO_GENERATION_LIMIT
  end

  def remaining_scenario_generation_count
    [ SCENARIO_GENERATION_LIMIT - scenario_generation_count, 0 ].max
  end

  def reserve_scenario_generation!(scenario)
    with_lock do
      return :already_generating if scenarios.generating.exists?
      return :limit_reached unless scenario_generation_available?

      scenario.generation_status = :generating
      scenario.save!

      increment!(:scenario_generation_count)
    end

    :reserved
  end

  def refund_scenario_generation!
    with_lock do
      decrement!(:scenario_generation_count) if scenario_generation_count.positive?
    end
  end

  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, uniqueness: true

  validates :password,
            length: { minimum: 3 },
            if: -> { new_record? || changes[:crypted_password] }
  validates :password,
            confirmation: true,
            if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation,
            presence: true,
            if: -> { new_record? || changes[:crypted_password] }
end
