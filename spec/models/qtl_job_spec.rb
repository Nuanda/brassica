require 'rails_helper'

RSpec.describe QtlJob do
  describe '#table_data' do
    let(:lm) { create(:linkage_map) }

    it 'gets proper columns' do
      qtlj = create(:qtl_job)
      table_data = QtlJob.table_data
      expect(table_data.count).to eq 1
      expect(table_data[0]).to eq [
        qtlj.qtl_job_name,
        qtlj.qtl_software,
        qtlj.qtl_method,
        qtlj.threshold_specification_method,
        qtlj.interval_type,
        qtlj.inner_confidence_threshold,
        qtlj.outer_confidence_threshold,
        qtlj.qtl_statistic_type,
        qtlj.date_run,
        qtlj.qtls.count,
        qtlj.id
      ]
    end
  end
end
