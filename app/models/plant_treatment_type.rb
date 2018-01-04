# Represents a plant treatment as defined in the Plant Experimental Conditions
# Ontology by term PECO:0001001 and its descendants.
class PlantTreatmentType < ActiveRecord::Base
  ROOT_TERM = "PECO:0001001"
  BIOTIC_ROOT_TERM = "PECO:0007357"
  CHEMICAL_ROOT_TERM = "PECO:0007189"
  ANTIBIOTIC_ROOT_TERM = "PECO:0007041"
  HERBICIDE_ROOT_TERM = "PECO:0007183"
  FUNGICIDE_ROOT_TERM = "PECO:0007268"
  PESTICIDE_ROOT_TERM = "PECO:0007167"
  HORMONE_ROOT_TERM = "PECO:0007165"
  FERTILIZER_ROOT_TERM = "PECO:0007085"

  validates :name, :term, presence: true

  def parents
    PlantTreatmentType.where(id: parent_ids) if parent_ids.present?
  end
end