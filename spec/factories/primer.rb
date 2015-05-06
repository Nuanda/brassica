FactoryGirl.define do
  factory :primer do |p|
    sequence(:primer) {|n| "#{Faker::Lorem.word}_#{n}"}
    sequence_id { Faker::Number.number(7).to_s }
    sequence_source_acronym { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    annotable
  end
end
