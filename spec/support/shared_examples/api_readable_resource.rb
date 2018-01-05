RSpec.shared_examples "API-readable resource" do |model_klass|
  model_name = model_klass.name.underscore

  let(:parsed_response) { JSON.parse(response.body) }

  context "with no api key" do
    describe "GET /api/v1/#{model_name.pluralize}" do
      it "returns 401" do
        get "/api/v1/#{model_name.pluralize}"

        expect(response.status).to eq 401
        expect(parsed_response['reason']).not_to be_empty
      end
    end

    describe "GET /api/v1/#{model_name.pluralize}/:id" do
      let!(:resource) { create model_name.to_sym }

      it "returns 401" do
        get "/api/v1/#{model_name.pluralize}/#{resource.id}"

        expect(response.status).to eq 401
        expect(parsed_response['reason']).not_to be_empty
      end
    end
  end

  context "with invalid api key" do
    let(:demo_key) { I18n.t('api.general.demo_key') }

    describe "GET /api/v1/#{model_name.pluralize}" do
      it "returns 401" do
        get "/api/v1/#{model_name.pluralize}", {}, { "X-BIP-Api-Key" => "invalid" }

        expect(response.status).to eq 401
        expect(parsed_response['reason']).not_to be_empty
      end

      it "shows gentle reminder if one is using demo key" do
        get "/api/v1/#{model_name.pluralize}", {}, { "X-BIP-Api-Key" => demo_key }

        expect(response.status).to eq 401
        expect(parsed_response['reason']).to eq "Please use your own, personal API key"
      end
    end

    describe "GET /api/v1/#{model_name.pluralize}/:id" do
      let!(:resource) { create model_name.to_sym }

      it "returns 401" do
        get "/api/v1/#{model_name.pluralize}/#{resource.id}", {}, { "X-BIP-Api-Key" => "invalid" }

        expect(response.status).to eq 401
        expect(parsed_response['reason']).not_to be_empty
      end
    end
  end

  context "with valid api key" do
    let(:api_key) { create(:api_key) }

    describe "GET /api/v1/#{model_name.pluralize}" do
      describe "response" do
        let!(:resources) { create_list(model_name.to_sym, 3) }

        it "renders existing resources" do
          get "/api/v1/#{model_name.pluralize}", {}, { "X-BIP-Api-Key" => api_key.token }

          expect(response).to be_success
          expect(parsed_response).to have_key(model_name.pluralize)
          expect(parsed_response[model_name.pluralize].count).to eq resources.size
        end

        it "filters forbidden resources out" do
          resource = model_klass.first
          if resource.has_attribute?(:published)
            resource.update_attribute(:published, false)
          end
          get "/api/v1/#{model_name.pluralize}", { }, { "X-BIP-Api-Key" => api_key.token }

          expect(response).to be_success
          expect(parsed_response).to have_key(model_name.pluralize)
          expect(parsed_response[model_name.pluralize].count).
            to eq resource.has_attribute?(:published) ? resources.size - 1 : resources.size
        end
      end

      describe "pagination" do
        let!(:resources) { create_list(model_name.to_sym, 3) }

        it "paginates returned resources" do
          get "/api/v1/#{model_name.pluralize}", {}, { "X-BIP-Api-Key" => api_key.token }

          expect(parsed_response['meta']).to include(
            'page' => 1,
            'per_page' => Kaminari.config.default_per_page,
            'total_count' => 3
          )
          expect(parsed_response[model_name.pluralize].count).to eq 3
        end

        it "allows pagination options" do
          get "/api/v1/#{model_name.pluralize}", { page: 2, per_page: 1 }, { "X-BIP-Api-Key" => api_key.token }

          expect(parsed_response['meta']).to include('page' => 2, 'per_page' => 1, 'total_count' => 3)
          expect(parsed_response[model_name.pluralize].count).to eq 1
        end
      end

      describe "filtering" do
        let(:filter_params) { { :search => 'foobar' } }
        before(:all) do
          WebMock.disable_net_connect!(allow_localhost: true)
        end

        if model_klass.ancestors.include?(Filterable)
          it "uses .filter if params given" do
            expect(model_klass).to receive(:filter).with(filter_params).and_call_original

            get "/api/v1/#{model_name.pluralize}", { model_name => filter_params }, { "X-BIP-Api-Key" => api_key.token }

            expect(response).to be_success
          end

          it 'supports filtering with query param for all visible attributes' do
            if model_klass.respond_to?(:table_columns)
              model_klass.params_for_filter(model_klass.table_columns + ['id']).each do |attribute|
                expect(model_klass.permitted_params.dup.extract_options![:query]).
                  to include attribute
                value = case model_klass.columns_hash[attribute].type
                          when :date
                            '2008-12-12'
                          else
                            'text default'
                        end
                query = { :query => { attribute => value } }

                expect(model_klass).to receive(:filter).with(query).and_call_original

                get "/api/v1/#{model_name.pluralize}", { model_name => query }, { "X-BIP-Api-Key" => api_key.token }
              end
            end
          end

          it 'always supports filtering with id param' do
            resource = create(model_name.to_sym)
            query = { query: { id: resource.id } }

            get "/api/v1/#{model_name.pluralize}", { model_name => query }, { "X-BIP-Api-Key" => api_key.token }

            expect(response).to be_success
            expect(parsed_response).to have_key(model_name.pluralize)
            expect(parsed_response[model_name.pluralize].first['id']).to eq resource.id
          end
        end

        if model_klass.ancestors.include?(Searchable)
          it 'supports fetch query param', :elasticsearch do
            hit_attribute = model_klass.indexed_json_structure[:only].first
            term = create(model_name.to_sym).send(hit_attribute)
            fetch_params = { fetch: term }

            expect(Search).to receive(:new).at_least(1).with(term).and_call_original
            expect(model_klass).to receive(:filter).with(fetch_params).and_call_original

            get "/api/v1/#{model_name.pluralize}", { model_name => fetch_params }, { "X-BIP-Api-Key" => api_key.token }

            expect(response).to be_success
          end
        end
      end
    end

    describe "GET /api/v1/#{model_name.pluralize}/:id" do
      let!(:resource) { create model_name.to_sym }
      let(:parsed_object) { JSON.parse(response.body)[model_name] }

      it "returns requested resource" do
        get "/api/v1/#{model_name.pluralize}/#{resource.id}", { }, { "X-BIP-Api-Key" => api_key.token }

        expect(response).to be_success
        expect(parsed_response).to have_key(model_name)
      end

      it "never shows blacklisted columns" do
        get "/api/v1/#{model_name.pluralize}/#{resource.id}", { }, { "X-BIP-Api-Key" => api_key.token }

        expect(parsed_object).not_to have_key('user_id')
        expect(parsed_object).not_to have_key('user')
        expect(parsed_object).not_to have_key('created_at')
        expect(parsed_object).not_to have_key('updated_at')
      end

      it "returns blank when resource is forbidden" do
        if resource.has_attribute?(:published)
          resource.update_attribute(:published, false)
        end
        get "/api/v1/#{model_name.pluralize}/#{resource.id}", { }, { "X-BIP-Api-Key" => api_key.token }

        if resource.has_attribute?(:published)
          expect(response.status).to eq 401
          expect(parsed_response['reason']).
            to eq 'This is a private resource of another user'
        else
          expect(parsed_response).to have_key(model_name)
        end
      end

      context 'when run for Relatable model' do
        if model_klass.ancestors.include?(Relatable)
          it "excludes counters" do
            get "/api/v1/#{model_name.pluralize}/#{resource.id}", { }, { "X-BIP-Api-Key" => api_key.token }

            model_klass.count_columns.each do |count_column|
              count_column = count_column.split(/ as /i)[-1]
              expect(parsed_object).not_to have_key(count_column)
            end
          end
        end
      end
    end
  end
end
