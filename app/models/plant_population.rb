class PlantPopulation < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  index_name ['brassica', Rails.env, base_class.name.underscore.pluralize].join("_")

  belongs_to :taxonomy_term

  belongs_to :population_type

  belongs_to :male_parent_line, class_name: 'PlantLine',
             foreign_key: 'male_parent_line_id'

  belongs_to :female_parent_line, class_name: 'PlantLine',
             foreign_key: 'female_parent_line_id'

  has_many :plant_population_lists

  has_many :linkage_maps

  has_many :population_loci, class_name: 'PopulationLocus'

  has_many :plant_trials

  has_and_belongs_to_many :plant_lines,
                          join_table: 'plant_population_lists'

  after_touch { __elasticsearch__.index_document }

  include Relatable
  include Filterable

  validates :name,
            presence: true,
            allow_blank: true

  scope :by_name, -> { order('plant_populations.name') }

  def self.table_data(params = nil)
    query = (params && (params[:query] || params[:fetch])) ? filter(params) : all
    query.
      includes(:female_parent_line, :male_parent_line, :taxonomy_term, :population_type).
      by_name.
      pluck(*(table_columns + count_columns + ref_columns))
  end

  def self.table_columns
    [
      'taxonomy_terms.name',
      'plant_populations.name',
      'canonical_population_name',
      'plant_lines.plant_line_name AS female_parent_line',
      'male_parent_lines_plant_populations.plant_line_name AS male_parent_line',
      'pop_type_lookup.population_type',
      'description'
    ]
  end

  def self.count_columns
    [
      'plant_population_lists_count AS plant_lines_count',
      'linkage_maps_count',
      'plant_trials_count'
    ]
  end

  def as_indexed_json(options = {})
    plant_line_attrs = [
      :plant_line_name
    ]

    as_json(
      only: [
        :name, :canonical_population_name, :description
      ],
      include: {
        taxonomy_term: { only: [:name] },
        population_type: { only: [:population_type] },
        female_parent_line: { only: plant_line_attrs },
        male_parent_line: { only: plant_line_attrs },
      }
    )
  end

  def self.permitted_params
    [
      :fetch,
      query: [
        'id',
        'name'
      ]
    ]
  end

  def self.ref_columns
    [
      'female_parent_line_id',
      'male_parent_line_id'
    ]
  end

  include Annotable
end
