require 'singleton'
class Brapi::V1::GermplasmQueries
  include Singleton

  def initialize
    @connection = ActiveRecord::Base.connection.raw_connection    
    @connection.exec("set statement_timeout to 10000;")     
  end

  # processing result: https://github.com/plantbreeding/API/blob/master/Specification/Germplasm/GermplasmSearchGET.md 
  # All possible fields to return:
  # germplasmDbId, defaultDisplayName, accessionNumber, germplasmName, germplasmPUI, pedigree, 
  # seedSource, synonyms, commonCropName, instituteCode, instituteName, biologicalStatusOfAccessionCode, 
  # countryOfOriginCode, typeOfGermplasmStorageCode, genus, species, taxonIds, speciesAuthority, subtaxa, subtaxaAuthority, 
  # donors, acquisitionDate

  def germplasm_search_query(query_params, count_mode:)
    germplasm_pui= query_params[:germplasm_pui] 
    germplasm_db_id= query_params[:germplasm_db_id]
    germplasm_name= query_params[:germplasm_name] 
    page= query_params[:page] 
    page_size= query_params[:page_size]
    
    
    # where conditions
    where_query = " "
    where_atts = []
    where_atts_count = 0
    
    # TO BE DEFINED
    #if germplasm_pui.present? 
    
    if germplasm_db_id.present?   # plant_accessions.plant_accession
      where_atts_count+= 1
      where_query = where_query + "where plant_accessions.plant_accession = $"+where_atts_count.to_s
      where_atts<< germplasm_db_id
    end
     
    if germplasm_name.present?   # plant_lines.plant_variety_name or plant_lines.common_name
      where_atts_count+= 1
      where_query = where_query + (where_atts_count>0?" and ":" where ") 
      where_query = where_query + " (plant_lines.plant_variety_name = $"+where_atts_count.to_s+
      " OR plant_lines.common_name = $"+where_atts_count.to_s+")"
      where_atts<< germplasm_name
    end
    
    # Until ORCID implementation is done, we only must retrieve published or not owned datasets
    where_query = where_query + (where_atts_count>0?" and ":" where ") 
    where_query += <<-SQL.strip_heredoc
      ((plant_accessions.user_id IS NULL OR plant_accessions.published = TRUE) AND
       (plant_populations.user_id IS NULL OR plant_populations.published = TRUE) AND
       (plant_lines.user_id IS NULL OR plant_lines.published = TRUE) AND
       (plant_varieties_from_lines.user_id IS NULL OR plant_varieties_from_lines.published = TRUE) AND
       (plant_varieties_from_accessions.user_id IS NULL OR plant_varieties_from_accessions.published = TRUE) )
    SQL
    
    
    # select clauses
    
    select_query = <<-SQL.strip_heredoc
      SELECT DISTINCT ON (plant_accessions.id)
      plant_accessions.id,
      plant_accessions.plant_accession as "germplasmDbId", 
      case 
        when plant_lines.common_name != null then plant_lines.common_name
        else plant_lines.plant_variety_name
      end as "defaultDisplayName",
      plant_accessions.plant_accession as "accessionNumber",
      plant_lines.common_name as "commonCropName",
      null as "instituteCode",
      plant_accessions.originating_organisation as "instituteName",
      plant_populations.population_type as "biologicalStatusOfAccessionCode",
      case 
        when countries_registered_from_lines.id != null then countries_registered_from_lines.country_code
        else countries_registered_from_accessions.country_code
      end as "countryOfOriginCode",
      'Brassica' as "genus",
      regexp_replace(taxonomy_terms.name, '( var.).*$', '') as "species",  
      taxonomy_terms.name as "subtaxa" 
    SQL
    
    # TODO : germplasmName
    # TODO : germplasmPUI
    # TODO : pedigree
    # TODO : seedSource
    # TODO : synonyms
    # TODO : instituteCode mandatory : to be implemented. To review instituteName
    # TODO : typeOfGermplasmStorageCode
    # TODO : taxonIds
    # TODO : speciesAuthority
    # TODO : subtaxaAuthority   
    # TODO : donors
    # TODO : acquisitionDate
    
    # joins
    
    joins_query = "
    FROM plant_accessions
    INNER JOIN plant_lines ON plant_accessions.plant_line_id = plant_lines.id
    INNER JOIN plant_population_lists ON plant_lines.id = plant_population_lists.plant_line_id
    INNER JOIN plant_populations ON plant_population_lists.plant_population_id = plant_populations.id
    LEFT JOIN plant_varieties AS plant_varieties_from_lines ON plant_lines.plant_variety_id = plant_varieties_from_lines.id 
    LEFT JOIN plant_varieties AS plant_varieties_from_accessions ON plant_accessions.plant_variety_id = plant_varieties_from_accessions.id 
    LEFT JOIN plant_variety_country_registered AS plant_variety_country_registered_from_lines ON plant_varieties_from_lines.id = plant_variety_country_registered_from_lines.plant_variety_id 
    LEFT JOIN plant_variety_country_registered AS plant_variety_country_registered_from_accessions ON plant_varieties_from_accessions.id = plant_variety_country_registered_from_accessions.plant_variety_id 
    LEFT JOIN countries AS countries_registered_from_lines ON plant_variety_country_registered_from_lines.country_id = countries_registered_from_lines.id 
    LEFT JOIN countries AS countries_registered_from_accessions ON plant_variety_country_registered_from_accessions.country_id = countries_registered_from_accessions.id 
    LEFT JOIN taxonomy_terms ON plant_lines.taxonomy_term_id = taxonomy_terms.id
    "
    
    
    if count_mode
      total_query = "SELECT COUNT(*) FROM ("+select_query + joins_query + where_query +") AS total_entries_count"

      result_object = execute_statement(total_query, where_atts)
    else
      # order
      order_query =  " ORDER BY plant_accessions.id desc"
      
      # pagination
      pagination_query = pagination_query(page, page_size)
      
      total_query = select_query + joins_query + where_query + order_query + pagination_query

      result_object = execute_statement(total_query, where_atts)
    end
    
    result_object
  end



  private


  def execute_statement(sql, atts)
    results = []
    # There should be only one 'brapi_statement' prepared and executing running at the same time,
    # at least until the previous one has been deallocated
    Thread.exclusive do
      @connection.prepare('brapi_statement', sql)
      begin
        if( (atts != nil) && !(atts.empty?) )
          results = @connection.exec_prepared("brapi_statement", atts)
        else
          results = @connection.exec_prepared("brapi_statement")
        end
      rescue PG::Error => e
        @connection.exec("ROLLBACK") 
        results = nil
        Rails.logger.warn { "Encountered an error executing a BrAPI germplasm-related query: #{e.message} #{e.backtrace.join("\n")}" }
      end
      @connection.exec("DEALLOCATE brapi_statement")
    end
    return results
  end
  
  
  def pagination_query(page, page_size)
    return " LIMIT "+page_size.to_s+" OFFSET "+((page-1)*page_size).to_s  
  end


end
