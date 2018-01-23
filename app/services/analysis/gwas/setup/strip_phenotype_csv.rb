class Analysis
  class Gwas
    class Setup
      class StripPhenotypeCsv
        include Helpers

        def initialize(analysis)
          @analysis = analysis
        end

        def applicable?
          true
        end

        def call
          return :all_samples_removed if common_samples.empty?
          return :ok if (analysis.meta['pheno_samples'] - common_samples).empty?

          pheno_status, pheno_csv_file = strip_pheno_csv

          check_pheno_status(pheno_status).tap do |status|
            if status == :ok
              phenotype_data_file.destroy
              create_csv_data_file(pheno_csv_file, data_type: :gwas_phenotype)
            end
          end
        end

        private

        attr_accessor :analysis, :common_samples

        def common_samples
          @common_samples ||= analysis.meta['geno_samples'] & analysis.meta['pheno_samples']
        end

        def strip_pheno_csv
          normalize_csv(phenotype_data_file.file, remove_rows: analysis.meta['pheno_samples'] - common_samples)
        end

        def check_pheno_status(status)
          case status
          when :ok then :ok
          when :all_rows_removed then :all_samples_removed
          else fail "Invalid status: #{status}"
          end
        end
      end
    end
  end
end
