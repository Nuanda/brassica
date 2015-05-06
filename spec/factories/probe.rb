FactoryGirl.define do
  factory :probe do
    sequence(:probe_name) {|n| "#{Faker::Lorem.word}_#{n}"}
    clone_name { Faker::Lorem.word }
    sequence_source_acronym { Faker::Lorem.word }
    date_described { Faker::Date.backward }
    sequence_id { Faker::Number.number(7).to_s }
    taxonomy_term
    annotable_no_owner_no_date
  end
end
