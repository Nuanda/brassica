FactoryBot.define do
  factory :primer do
    sequence(:primer) {|n| "#{Faker::Lorem.word}_#{n}"}
    sequence_id { Faker::Number.number(7).to_s }
    sequence_source_acronym { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    published_on { Date.today-8.days }
    user
    annotable

    after(:build) do |primer_registry, _|
      primer_registry.sequence = 'GATTACA'
    end
  end
end
