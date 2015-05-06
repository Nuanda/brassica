class Probe < ActiveRecord::Base

  belongs_to :taxonomy_term

  has_many :marker_assays

  validates :probe_name,
            presence: true

  validates :clone_name,
            presence: true

  validates :sequence_id,
            presence: true

  validates :sequence_source_acronym,
            presence: true

  include Relatable
  include Filterable
  include Pluckable

  def self.table_data(params = nil)
    query = (params && (params[:query] || params[:fetch])) ? filter(params) : all
    query.pluck_columns
  end

  def self.table_columns
    [
      'probe_name',
      'taxonomy_terms.name',
      'clone_name',
      'date_described',
      'sequence_id',
      'sequence_source_acronym'
    ]
  end

  def self.count_columns
    [
      'marker_assays_count'
    ]
  end

  private

  def self.permitted_params
    [
      query: [
        'id'
      ]
    ]
  end

  include Annotable
end
