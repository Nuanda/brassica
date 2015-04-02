class PlantLine < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  belongs_to :plant_variety

  belongs_to :taxonomy_term

  has_many :plant_population_lists

  has_many :fathered_descendants, class_name: 'PlantPopulation',
           foreign_key: 'male_parent_line_id'

  has_many :mothered_descendants, class_name: 'PlantPopulation',
           foreign_key: 'female_parent_line_id'

  has_many :plant_accessions

  has_and_belongs_to_many :plant_populations,
                          join_table: 'plant_population_lists'

  after_update { mothered_descendants.each(&:touch) }
  after_update { fathered_descendants.each(&:touch) }

  after_touch { __elasticsearch__.index_document }
  
  include Filterable
  include Pluckable

  scope :by_name, -> { order(:plant_line_name) }

  def self.filtered(params)
    query = filter(params)
    query.by_name.pluck_columns(table_columns)
  end

  def self.genetic_statuses
    order('genetic_status').pluck('DISTINCT genetic_status').reject(&:blank?)
  end

  def as_indexed_json(options = {})
    as_json(
      only: [
        :id, :plant_line_name, :common_name, :genetic_status,
        :previous_line_name
      ],
      include: {
        taxonomy_term: { only: [:name] }
      }
    )
  end

  private

  def self.permitted_params
    [
      search: [
        :plant_line_name,
        'plant_lines.plant_line_name'
      ],
      query: [
        'plant_populations.id',
        'plant_populations.name',
        plant_line_name: [],
        'plant_lines.plant_line_name' => []
      ]
    ]
  end

  def self.table_columns
    [
      'plant_line_name',
      'taxonomy_terms.name',
      'common_name',
      'previous_line_name',
      'date_entered',
      'data_owned_by',
      'organisation'
    ]
  end
end
