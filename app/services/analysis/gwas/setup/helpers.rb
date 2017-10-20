class Analysis
  class Gwas
    class Setup
      module Helpers
        def genotype_data_file(type = nil)
          scope = analysis.data_files.gwas_genotype
          scope = scope.send(type) if type
          scope.generated.first || scope.uploaded.first
        end

        def phenotype_data_file
          scope = analysis.data_files.gwas_phenotype
          scope.generated.first || scope.uploaded.first
        end

        def map_data_file
          scope = analysis.data_files.gwas_map
          scope.generated.first || scope.uploaded.first
        end

        def normalize_csv(file, remove_columns: [], remove_rows: [])
          Analysis::Gwas::CsvNormalizer.new.
            call(file, remove_columns: remove_columns, remove_rows: remove_rows)
        end

        def normalize_geno_csv(geno_csv_file = genotype_data_file(:csv).file)
          normalize_csv(geno_csv_file, remove_columns: analysis.meta['removed_mutations'])
        end

        def normalize_pheno_csv(pheno_csv_file = phenotype_data_file.file)
          normalize_csv(pheno_csv_file, remove_columns: analysis.meta['removed_traits'])
        end

        def create_csv_data_file(file, data_type:)
          analysis.data_files.create!(
            role: :input,
            origin: :generated,
            data_type: data_type,
            file: file,
            file_content_type: "text/csv",
            owner: analysis.owner
          )
        end

        # Return headers of columns for which there is less than two distinct
        # values (NA does not count). Such columns cannot be passed as input
        # for GWASSER.
        #
        # TODO: this could actually be done by CsvNormalizer itself saving
        # one pass through csv file
        def find_csv_columns_to_remove(csv_file)
          values_by_col_name = Hash.new { |h, k| h[k] = Set.new }

          CSV.open(csv_file.path) do |csv|
            headers = csv.readline

            csv.each do |row|
              row.each.with_index do |val, col_idx|
                values_by_col_name[headers[col_idx]] << val
              end
            end
          end

          values_by_col_name.
            select { |col_name, values| (values - ["NA"]).size < 2 }.
            keys - ["ID"]
        end

        def save_mutations_to_remove(geno_csv_file = genotype_data_file(:csv).file)
          find_csv_columns_to_remove(geno_csv_file).tap do |mutations|
            analysis.meta['removed_mutations'] = mutations
            analysis.save!
          end
        end

        def save_traits_to_remove(pheno_csv_file = phenotype_data_file.file)
          find_csv_columns_to_remove(pheno_csv_file).tap do |traits|
            analysis.meta['removed_traits'] = traits
            analysis.save!
          end
        end
      end
    end
  end
end
