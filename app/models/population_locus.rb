class PopulationLocus < ActiveRecord::Base

  belongs_to :plant_population, counter_cache: true
  belongs_to :marker_assay, counter_cache: true
  belongs_to :user

  has_many :map_positions
  has_many :map_locus_hits

  validates :mapping_locus,
            presence: true

  after_update { map_positions.each(&:touch) }
  after_update { map_locus_hits.each(&:touch) }

  include Relatable
  include Filterable
  include Pluckable
  include Searchable

  def self.table_data(params = nil)
    query = (params && (params[:query] || params[:fetch])) ? filter(params) : all
    query.pluck_columns
  end

  def self.table_columns
    [
      'plant_populations.name',
      'marker_assays.marker_assay_name',
      'mapping_locus',
      'defined_by_whom'
    ]
  end

  def self.count_columns
    [
      'map_positions_count',
      'map_locus_hits_count'
    ]
  end

  def self.permitted_params
    [
      :fetch,
      query: [
        'mapping_locus',
        'defined_by_whom',
        'plant_populations.id',
        'marker_assays.id',
        'id'
      ]
    ]
  end

  def self.ref_columns
    [
      'plant_population_id',
      'marker_assay_id'
    ]
  end

  include Annotable
end
