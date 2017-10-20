class Analysis
  class Gwas
    class Setup
      class GenotypeCsv
        include Helpers

        def initialize(analysis)
          @analysis = analysis
        end

        def applicable?
          genotype_data_file(:csv).try(:uploaded?)
        end

        def call
          save_mutations_to_remove

          geno_status, geno_csv_file = normalize_geno_csv

          check_geno_status(geno_status).tap do |status|
            create_csv_data_file(geno_csv_file, data_type: :gwas_genotype) if status == :ok
          end
        end

        private

        attr_accessor :analysis

        def check_geno_status(status)
          case status
          when :ok then :ok
          when :all_columns_removed then :all_mutations_removed
          else fail "Invalid status: #{status}"
          end
        end
      end
    end
  end
end
