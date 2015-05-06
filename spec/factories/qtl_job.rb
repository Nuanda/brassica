FactoryGirl.define do
  factory :qtl_job do
    sequence(:qtl_job_name) {|n| "#{Faker::Lorem.characters(11)}_#{n}"}
    # TODO FIXME this has to await fixing #205
    # 'linkage_map_id',
    qtl_software { Faker::Lorem.word }
    qtl_method { Faker::Lorem.word }
    threshold_specification_method { Faker::Lorem.sentence }
    interval_type { Faker::Lorem.sentence }
    inner_confidence_threshold { Faker::Number.number(1).to_s }
    outer_confidence_threshold { Faker::Number.number(1).to_s }
    qtl_statistic_type { Faker::Lorem.word }
    date_run { Faker::Date.backward }
    annotable
  end
end
