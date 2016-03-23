class TraitScore < ActiveRecord::Base

  belongs_to :plant_scoring_unit, counter_cache: true
  belongs_to :trait_descriptor, counter_cache: true
  belongs_to :user

  validates :score_value,
            presence: true

  include Filterable
  include Pluckable

  scope :of_trial, ->(plant_trial_id) {
    joins(:plant_scoring_unit).
    where(plant_scoring_units: { plant_trial_id: plant_trial_id })
  }

  def self.table_data(params = nil)
    query = (params && (params[:query] || params[:fetch])) ? filter(params) : all
    query.
        includes(plant_scoring_unit: { plant_trial: :plant_population, plant_accession: :plant_line }).
        includes(:trait_descriptor).
        pluck(*(table_columns + ref_columns))
  end

  def self.table_columns
    [
      'plant_trials.plant_trial_name',
      'plant_populations.name',
      'plant_lines.plant_line_name',
      'trait_descriptors.descriptor_name',
      'score_value',
      'trait_descriptors.units_of_measurements',
      'value_type',
      'scoring_date',
      'plant_scoring_units.scoring_unit_name'
    ]
  end

  def self.ref_columns
    [
      'plant_populations.id',
      'plant_lines.id',
      'plant_trials.id',
      'trait_descriptors.id',
      'plant_scoring_units.id'
    ]
  end

  def self.permitted_params
    [
      query: params_for_filter(table_columns) +
        [
          'trait_descriptor_id',
          'plant_scoring_units.plant_trial_id',
          'plant_scoring_units.id',
          'id'
        ]
    ]
  end

  include Annotable
end
