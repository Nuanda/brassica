class Submission::PlantTrialPublisher < Submission::Publisher

  private

  def associated_collections
    [plant_scoring_units, plant_accessions, trait_scores, trait_descriptors]
  end

  def plant_trial
    raise ArgumentError, "Wrong submission type" unless submission.trial?
    submission.submitted_object
  end

  def plant_scoring_units
    plant_trial.plant_scoring_units.where(user_id: submission.user)
  end

  def plant_accessions
    PlantAccession.where(user_id: submission.user,
                         id: plant_scoring_units.pluck("DISTINCT plant_accession_id"))
  end

  def trait_scores
    TraitScore.where(user_id: submission.user).of_trial(plant_trial.id)
  end

  def trait_descriptors
    TraitDescriptor.where(user_id: submission.user,
                          id: trait_scores.pluck("DISTINCT trait_descriptor_id"))
  end
end
