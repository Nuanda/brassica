class Analysis
  class Gwas
    class GenotypeCsvParser
      def call(io)
        Analysis::CsvParser.new.call(io, Result).tap do |result|
          check_errors(result)
        end
      end

      private

      def check_errors(parser_result)
        parser_result.errors << :no_id_column unless parser_result.headers.include?("ID")
        parser_result.errors << :no_mutations if parser_result.mutation_ids.blank?
        parser_result.errors << :no_samples if parser_result.sample_ids.blank?
      rescue CSV::MalformedCSVError
        parser_result.errors << :malformed_csv
      ensure
        parser_result.rewind
      end

      class Result < Analysis::CsvParser::Result
        def mutation_ids
          headers - %w(ID)
        end

        def sample_ids
          id_col_idx = headers.index("ID")

          return unless id_col_idx

          @sample_ids ||= csv.each.map { |row| row[id_col_idx] }
        end
      end
    end
  end
end
