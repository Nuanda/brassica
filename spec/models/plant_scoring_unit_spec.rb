require 'rails_helper'

RSpec.describe PlantScoringUnit do
  describe '#pluckable' do
    it 'gets proper data table columns' do
      psc = create(:plant_scoring_unit)
      plucked = PlantScoringUnit.pluck_columns
      expect(plucked.count).to eq 1
      expect(plucked[0]).
        to eq [
          psc.scoring_unit_name,
          psc.number_units_scored,
          psc.scoring_unit_sample_size,
          psc.scoring_unit_frame_size,
          psc.date_planted,
          psc.design_factor.design_factor_name,
          psc.plant_trial.plant_trial_name,
          psc.plant_part.plant_part,
          psc.trait_scores_count,
          psc.id
        ]
    end
  end
end