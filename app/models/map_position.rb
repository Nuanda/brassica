class MapPosition < ApplicationRecord
  belongs_to :linkage_group, counter_cache: true, touch: true
  belongs_to :population_locus, counter_cache: true, touch: true
  belongs_to :marker_assay, counter_cache: true, touch: true
  belongs_to :user

  after_update { map_locus_hits.each(&:touch) }
  before_destroy { map_locus_hits.each(&:touch) }

  has_many :map_locus_hits

  validates :map_position, presence: true

  include Relatable
  include Filterable
  include Pluckable
  include Searchable
  include Publishable
  include TableData

  def self.table_columns
    [
      'marker_assays.marker_assay_name',
      'map_position',
      'linkage_groups.linkage_group_label',
      'population_loci.mapping_locus'
    ]
  end

  def self.count_columns
    [
      'map_locus_hits_count'
    ]
  end

  def self.numeric_columns
    [
      'map_position'
    ]
  end

  def self.permitted_params
    [
      :fetch,
      query: [
        'marker_assay_name',
        'marker_assays.id',
        'map_position',
        'linkage_groups.id',
        'population_loci.id',
        'user_id',
        'id'
      ]
    ]
  end

  def self.ref_columns
    [
      'marker_assay_id',
      'linkage_group_id',
      'population_locus_id'
    ]
  end

  mapping dynamic: 'false' do
    indexes :marker_assay do
      indexes :marker_assay_name
    end
    indexes :linkage_group do
      indexes :linkage_group_label
    end
    indexes :population_locus do
      indexes :mapping_locus
    end

    MapPosition.numeric_columns.each do |column|
      indexes column, include_in_all: 'false'
    end
  end

  include Annotable
end
