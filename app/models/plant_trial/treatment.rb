class PlantTrial::Treatment < ActiveRecord::Base
  belongs_to :plant_trial, touch: true, inverse_of: :treatment

  has_many :antibiotic_applications, class_name: "PlantTrial::AntibioticTreatmentApplication", inverse_of: :treatment
  has_many :chemical_applications, class_name: "PlantTrial::ChemicalTreatmentApplication", inverse_of: :treatment
  has_many :biotic_applications, class_name: "PlantTrial::BioticTreatmentApplication", inverse_of: :treatment
  has_many :fertilizer_applications, class_name: "PlantTrial::FertilizerTreatmentApplication", inverse_of: :treatment
  has_many :hormone_applications, class_name: "PlantTrial::HormoneTreatmentApplication", inverse_of: :treatment
  has_many :fungicide_applications, class_name: "PlantTrial::FungicideTreatmentApplication", inverse_of: :treatment
  has_many :herbicide_applications, class_name: "PlantTrial::HerbicideTreatmentApplication", inverse_of: :treatment
  has_many :pesticide_applications, class_name: "PlantTrial::PesticideTreatmentApplication", inverse_of: :treatment

  validates :plant_trial, presence: true
  validates :air_temperature_day, temperature: true, allow_nil: true
  validates :air_temperature_night, temperature: true, allow_nil: true
  validates :salt, non_negative: true, allow_nil: true
  validates :watering_temperature, temperature: true, allow_nil: true
end