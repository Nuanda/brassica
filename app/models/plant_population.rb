class PlantPopulation < ActiveRecord::Base
  belongs_to :taxonomy_term
  belongs_to :population_type
  belongs_to :male_parent_line, class_name: 'PlantLine',
             foreign_key: 'male_parent_line_id'
  belongs_to :female_parent_line, class_name: 'PlantLine',
             foreign_key: 'female_parent_line_id'
  belongs_to :user

  after_update { population_loci.each(&:touch) }
  after_update { linkage_maps.each(&:touch) }
  after_update { plant_trials.each(&:touch) }
  before_destroy { population_loci.each(&:touch) }
  before_destroy { linkage_maps.each(&:touch) }
  before_destroy { plant_trials.each(&:touch) }

  has_many :linkage_maps, dependent: :nullify
  has_many :population_loci, dependent: :nullify
  has_many :plant_trials, dependent: :nullify

  has_many :plant_population_lists, dependent: :delete_all
  has_many :plant_lines, through: :plant_population_lists

  has_one :submission,
          ->(plant_population) { population.where(user_id: plant_population.user_id) },
          foreign_key: :submitted_object_id,
          dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :user, presence: { on: :create }
  validates :establishing_organisation, presence: { on: :create, message: 'Establishing organisation must be specified.' }

  after_update :cascade_visibility

  include Relatable
  include Filterable
  include Searchable
  include Publishable
  include AttributeValues

  scope :by_name, -> { order('plant_populations.name') }

  def self.table_data(params = nil, uid = nil)
    subquery = PlantLine.visible(uid)

    query = PlantPopulation.
      joins {[
        subquery.as('plant_lines').on { female_parent_line_id == plant_lines.id }.outer,
        subquery.as('male_parent_lines_plant_populations').on { male_parent_line_id == male_parent_lines_plant_populations.id }.outer,
        taxonomy_term.outer,
        population_type.outer
      ]}
    query = (params && (params[:query] || params[:fetch])) ? filter(params, query) : query
    query = query.
      where(arel_table[:user_id].eq(uid).or(arel_table[:published].eq(true)))

    query = join_counters(query, uid)
    query = query.by_name
    query.pluck(*(table_columns + privacy_adjusted_count_columns + ref_columns))
  end

  def self.table_columns
    [
      'taxonomy_terms.name',
      'plant_populations.name',
      'canonical_population_name',
      'plant_lines.plant_line_name AS female_parent_line',
      'male_parent_lines_plant_populations.plant_line_name AS male_parent_line',
      'pop_type_lookup.population_type',
      'description',
      'establishing_organisation'
    ]
  end

  def self.count_columns
    [
      'plant_population_lists_count AS plant_lines_count',
      'linkage_maps_count',
      'plant_trials_count',
      'population_loci_count'
    ]
  end

  def self.indexed_json_structure
    {
      only: [
        :name, :canonical_population_name, :description, :establishing_organisation
      ],
      include: {
        taxonomy_term: { only: :name },
        population_type: { only: :population_type },
        female_parent_line: { only: :plant_line_name },
        male_parent_line: { only: :plant_line_name },
      }
    }
  end

  def self.permitted_params
    [
      :fetch,
      search: [
        'name',
        'canonical_population_name',
        'description',
        'establishing_organisation'
      ],
      query: [
        'name',
        'canonical_population_name',
        'description',
        'establishing_organisation',
        'user_id',
        'id'
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

  private

  def cascade_visibility
    if published_changed?
      plant_population_lists.each do |ppl|
        ppl.update_attributes!(published: self.published?, published_on: Time.now)
      end
    end
  end
end
