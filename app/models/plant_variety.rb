class PlantVariety < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  index_name ['brassica', Rails.env, base_class.name.underscore.pluralize].join("_")

  has_and_belongs_to_many :countries_of_origin,
                          class_name: 'Country',
                          join_table: 'plant_variety_country_of_origin'

  has_and_belongs_to_many :countries_registered,
                          class_name: 'Country',
                          join_table: 'plant_variety_country_registered'

  has_many :plant_lines

  include Filterable
  include Pluckable

  scope :by_name, -> { order(:plant_variety_name) }

  def self.table_data(params = nil)
    query = (params && (params[:query] || params[:fetch])) ? filter(params) : all
    query.by_name.pluck_columns
  end

  def self.table_columns
    [
      'plant_variety_name',
      'crop_type',
      'data_attribution',
      'year_registered',
      'breeders_variety_code',
      'owner',
      'quoted_parentage',
      'female_parent',
      'male_parent'
    ]
  end

  def as_indexed_json(options = {})
    as_json(
      only: [ :plant_variety_name ]
    )
  end

  def self.permitted_params
    [
      :fetch,
      query: [
        'id'
      ],
      search: [
        :plant_variety_name
      ]
    ]
  end

  include Annotable
end
