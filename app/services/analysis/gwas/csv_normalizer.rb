class Analysis
  class Gwas
    # Copies given CSV file intended to be used as GWASSER input making sure
    # that its headers and sample names do not contain special characters
    # except for underscore.
    class CsvNormalizer
      def call(file, remove_columns: [], remove_rows: [])
        normalized_csv = CSV.generate(force_quotes: true) do |csv|
          CSV.open(file.path, "r") do |existing_csv|
            headers = existing_csv.readline

            return :all_columns_removed if headers.size - remove_columns.size < 2

            remove_col_idxes = remove_columns.map { |col| headers.index(col) }

            existing_csv.rewind
            existing_csv.each.with_index do |row, row_idx|
              next if remove_rows.include?(row[0])

              csv << row.map.with_index do |val, col_idx|
                next if remove_col_idxes.include?(col_idx)

                if row_idx == 0 || col_idx == 0
                  # TODO: make sure normalized names are unique
                  val.strip.gsub(/\W+/, '_')
                else
                  val.strip
                end
              end.compact
            end
          end
        end

        tmpfile = NamedTempfile.new(".csv")
        tmpfile.original_filename = "#{File.basename(file.original_filename, ".csv")}.normalized.csv"
        tmpfile << normalized_csv
        tmpfile.flush
        tmpfile.rewind

        [:ok, tmpfile]
      end
    end
  end
end
