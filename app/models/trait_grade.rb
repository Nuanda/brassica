class TraitGrade < ApplicationRecord
  belongs_to :trait_descriptor

  validates :trait_grade,
            presence: true

  include Annotable
end
