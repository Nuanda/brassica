class Country < ApplicationRecord

  has_and_belongs_to_many :originating_plant_varieties,
                          class_name: 'PlantVariety',
                          join_table: 'plant_variety_country_of_origin'

  has_and_belongs_to_many :registered_plant_varieties,
                          class_name: 'PlantVariety',
                          join_table: 'plant_variety_country_registered'

  has_many :plant_trials

  validates :country_code,
            presence: true,
            uniqueness: true

  default_scope -> { order :country_name }

  include Filterable

  def self.permitted_params
    [
      search: [
        'country_code',
        'country_name'
      ],
      query: [
        'id'
      ]
    ]
  end
end
