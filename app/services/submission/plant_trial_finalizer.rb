class Submission::PlantTrialFinalizer

  attr_reader :new_trait_descriptors, :plant_trial

  def initialize(submission)
    raise ArgumentError, "Submission already finalized" if submission.finalized?

    self.submission = submission
  end

  def call
    ActiveRecord::Base.transaction do
      create_new_trait_descriptors
      create_scoring
      create_plant_trial
      update_submission
    end
    submission.finalized?
  end

  private

  attr_accessor :submission

  def create_new_trait_descriptors
    @new_trait_descriptors = (submission.content.step02.new_trait_descriptors || []).map do |attrs|
      attrs = attrs.with_indifferent_access
      attrs = attrs.merge(user_data)
      attrs = attrs.merge(published: publish?)
      TraitDescriptor.create!(attrs)
    end
  end

  def create_scoring
    trait_mapping = submission.content.step03.trait_mapping

    @new_plant_scoring_units = (submission.content.step03.trait_scores || {}).map do |plant_id, scores|
      new_plant_scoring_unit = PlantScoringUnit.create!(
        user_data.merge(scoring_unit_name: plant_id, published: publish?)
      )

      (scores || {}).
        select{ |_, value| value.present? }.
        map do |col_index, value|
          trait_descriptor = get_nth_trait_descriptor(trait_mapping[col_index])
          rollback(1) unless trait_descriptor

          TraitScore.create!(
            user_data.merge(trait_descriptor: trait_descriptor,
                            score_value: value,
                            plant_scoring_unit_id: new_plant_scoring_unit.id,
                            published: publish?)
          )
      end
      new_plant_scoring_unit
    end
  end

  def create_plant_trial
    attrs = submission.content.step01.to_h.merge(user_data)

    if plant_population = PlantPopulation.find_by(id: submission.content.step01.plant_population_id)
      attrs.merge!(plant_population_id: plant_population.id)
    else
      submission.content.update(:step01, submission.content.step01.to_h.except('plant_population_id'))
      submission.save!
      rollback(0)
    end

    attrs.merge!(submission.content.step04.to_h.except(:visibility))
    attrs.merge!(plant_scoring_units: @new_plant_scoring_units)
    attrs.merge!(published: publish?)

    if PlantTrial.where(plant_trial_name: attrs[:plant_trial_name]).exists?
      rollback(0)
    else
      @plant_trial = PlantTrial.create!(attrs)
    end
  end

  def update_submission
    submission.update_attributes!(
      finalized: true,
      published: publish?,
      submitted_object_id: @plant_trial.id
    )
  end

  def rollback(to_step)
    submission.errors.add(:step, to_step)
    raise ActiveRecord::Rollback
  end

  def user_data
    {
      date_entered: Date.today,
      entered_by_whom: submission.user.full_name,
      user: submission.user
    }
  end

  def get_nth_trait_descriptor(n)
    trait = submission.content.step02.trait_descriptor_list[n]
    if trait.to_i > 0
      TraitDescriptor.find_by(id: trait)
    else
      @new_trait_descriptors.detect{ |ntd| ntd.descriptor_name == trait }
    end
  end

  def publish?
    @publish ||= submission.content.step04.visibility.to_s == 'published'
  end
end
