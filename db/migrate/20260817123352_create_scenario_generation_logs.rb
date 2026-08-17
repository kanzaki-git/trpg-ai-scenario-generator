class CreateScenarioGenerationLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :scenario_generation_logs do |t|
      t.references :user,
                   null: false,
                   foreign_key: true

      t.references :scenario,
                   null: true,
                   foreign_key: { on_delete: :nullify }

      t.string :status,
               null: false,
               default: "processing"

      t.string :openai_response_id
      t.string :openai_model,
               null: false

      t.integer :input_tokens,
                null: false,
                default: 0

      t.integer :cached_input_tokens,
                null: false,
                default: 0

      t.integer :output_tokens,
                null: false,
                default: 0

      t.integer :reasoning_tokens,
                null: false,
                default: 0

      t.integer :total_tokens,
                null: false,
                default: 0

      t.decimal :input_price_per_million_usd,
                precision: 10,
                scale: 4,
                null: false,
                default: 0

      t.decimal :cached_input_price_per_million_usd,
                precision: 10,
                scale: 4,
                null: false,
                default: 0

      t.decimal :output_price_per_million_usd,
                precision: 10,
                scale: 4,
                null: false,
                default: 0

      t.decimal :estimated_cost_usd,
                precision: 12,
                scale: 8,
                null: false,
                default: 0

      t.datetime :started_at,
                 null: false

      t.datetime :finished_at
      t.string :openai_status
      t.string :error_class
      t.text :error_message

      t.timestamps
    end

    add_index :scenario_generation_logs,
              :openai_response_id,
              unique: true

    add_index :scenario_generation_logs,
              %i[user_id created_at]
  end
end
