class PlantPopulationList < ApplicationRecord
  belongs_to :plant_line
  belongs_to :plant_population, counter_cache: true, touch: true
  belongs_to :user

  validates :plant_line_id,
            presence: true,
            uniqueness: { scope: :plant_population }

  validates :plant_population_id, presence: true

  include Publishable

  def self.permitted_params
    [
      query: [
        'user_id',
        'id'
      ]
    ]
  end

  include Annotable
end
