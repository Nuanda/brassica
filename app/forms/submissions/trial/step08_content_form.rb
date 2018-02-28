module Submissions
  module Trial
    class Step08ContentForm < PlantTrialForm
      property :plant_trial_name
      property :project_descriptor
      property :plant_population_id

      property :plant_trial_description
      property :trial_year
      property :institute_id
      property :country_id
      property :trial_location_site_name
      property :place_name
      property :latitude
      property :longitude
      property :altitude
      property :terrain
      property :soil_type
      property :statistical_factors

      property :visibility, default: 'private'
      property :data_owned_by
      property :data_provenance
      property :comments

      validates :plant_trial_name, presence: true
      validates :plant_trial_description, presence: true
      validates :project_descriptor, presence: true
      validates :plant_population_id, presence: true
      validates :country_id, presence: true
      validates :institute_id, presence: true
      validates :latitude, allow_blank: true, numericality: {
        greater_than_or_equal_to: -90,
        less_than_or_equal_to: 90
      }
      validates :longitude, allow_blank: true, numericality: {
        greater_than_or_equal_to: -180,
        less_than_or_equal_to: 180
      }
      validates :altitude, numericality: true, allow_blank: true
      validates :trial_year, numericality: { only_integer: true,
                                             less_than_or_equal_to: Date.today.year }
      validates :place_name, presence: true
      validates :visibility, inclusion: { in: %w(published private) }

      validate do
        if PlantTrial.where(plant_trial_name: plant_trial_name).exists?
          errors.add(:plant_trial_name, :taken)
        end
      end

      def plant_population
        return unless plant_population_id.present?
        PlantPopulation.find_by(id: plant_population_id)
      end
    end
  end
end
