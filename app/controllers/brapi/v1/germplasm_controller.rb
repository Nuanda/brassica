class Brapi::V1::GermplasmController < Brapi::BaseController
  include Swagger::Blocks
  # Swagger API doc
  swagger_path '/brapi/v1/germplasm-search' do
    operation :get do
      key :summary, 'Search of germplasms by different params'
      key :description, 'Returns zero, one or multiple germplasms'
      key :operationId, 'germplasm-search'
      key :tags, [
        'Germplasm'
      ]
     # TODO: parameter :germplasmPUI
      parameter :germplasmDbId
      parameter :germplasmName
      parameter :page
      parameter :pageSize
      
      response :not_found do
        key :description, 'There were not any germplasm with the required params' 
      end
      response :unprocessable_entity do
        key :description, 'There was an error managing the internal query' 
      end
      response :default do
        key :description, 'list of germplasms'
      end
    end
  end
  
  
  
  attr_accessor :request_params, :user
  

  def search
    # accepted params: germplasmPUI , germplasmDbId , germplasmName , pageSize , page
    if !params['germplasmPUI'].present? && !params['germplasmDbId'].present? && !params['germplasmName'].present?
      raise ActionController::ParameterMissing.new('Not Found')
    else 
      germplasm_queries = Brapi::V1::GermplasmQueries.instance
      page = get_page
      page_size = get_page_size 
          
      query_params = { 
        germplasm_pui: params['germplasmPUI'], 
        germplasm_db_id: params['germplasmDbId'],
        germplasm_name: params['germplasmName'],
        page: page, 
        page_size: page_size
      }
      
      result_object = germplasm_queries.germplasm_search_query(query_params, count_mode: false)   
          
      if result_object.count == 0
        render json: { reason: 'Resource not found' }, status: :not_found  # 404
      else
        json_result_array = []
        
        # any programmatic data manipulation can be done here
        result_object.each do |row|
          # To check authentication and ownership when ORCID is supported by BrAPI
          # We currently only retrieve public records. This is already done at query level
          #if (!row[:user_id] || row[:published] )
          json_result_array << row
          #end
        end
        
        # pagination data returned
        
        result_count_object = germplasm_queries.germplasm_search_query(query_params, count_mode: true)
        total_count = result_count_object.values.first[0].to_i
        total_pages = (total_count/page_size.to_f).ceil
        
        json_response = { 
          metadata: json_metadata(page_size, page, total_count, total_pages),
          result: {
            data: json_result_array
          }
        }
       
        render json: json_response, except: ["id", "user_id", "created_at", "updated_at", "total_entries_count"]
      end
    end
  end



  private

  
  def get_page
    return (params[:page].to_i != 0)?params[:page].to_i : 1
  end
  
  def get_page_size
    return (params[:pageSize].to_i != 0)?params[:pageSize].to_i : 1000 
  end
  
  def json_metadata(page_size, current_page, total_count, total_pages)
    json_metadata = {
      status: [],
      datafiles: [],
      pagination: {
        pageSize: page_size, # like 'per_page' in CollectionDecorator
        currentPage:  current_page, # like 'page' in CollectionDecorator
        totalCount: total_count, # like 'total_count' in CollectionDecorator
        totalPages: total_pages 
      }
    }
  end
  


end
