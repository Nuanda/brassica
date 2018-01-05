FactoryBot.define do
  factory :map_locus_hit do
    sequence(:consensus_group_assignment) {|n| "#{Faker::Lorem.characters(1)}_#{n}"}
    canonical_marker_name { Faker::Lorem.word }
    associated_sequence_id { Faker::Number.number(8).to_s }
    sequence_source_acronym { Faker::Lorem.word }
    atg_hit_seq_id { Faker::Lorem.word }
    atg_hit_seq_source { Faker::Lorem.word }
    bac_hit_seq_id { Faker::Number.number(8).to_s }
    bac_hit_seq_source { Faker::Lorem.word }
    bac_hit_name { Faker::Lorem.word }
    published_on { Date.today-8.days }
    linkage_group
    linkage_map
    population_locus
    map_position
    user
  end
end
