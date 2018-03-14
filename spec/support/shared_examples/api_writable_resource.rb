RSpec.shared_examples "API-writable resource" do |model_klass|
  model_name = model_klass.name.underscore
  model = Api::Model.new(model_name)

  let(:parsed_response) { JSON.parse(response.body) }
  let(:required_attrs) { required_attributes(model_klass) - [:user]}
  let(:habtm_assocs) { model.has_and_belongs_to_many_associations }
  let(:related_models) { all_belongs_to(model_klass) - [:user] }

  it 'has all required attributes described correctly in docs' do
    props = I18n.t("api.#{model_klass.name.underscore}.attrs")
    required_props = props.select{ |p| p[:create] && p[:create].include?('required') }
    expect(required_props.map{ |rp| rp[:name].to_sym }).to match_array required_attrs
  end

  it 'belongs to user' do
    expect(all_belongs_to(model_klass)).to include :user
  end

  it 'has both date_entered and entered_by_whom attributes' do
    expect(model_klass.column_names).to include('entered_by_whom')
    expect(model_klass.column_names).to include('date_entered')
  end

  context "with no api key" do
    describe "POST /api/v1/#{model_name.pluralize}" do
      it "returns 401" do
        get "/api/v1/#{model_name.pluralize}"

        expect(response.status).to eq 401
        expect(parsed_response['reason']).not_to be_empty
      end
    end
  end

  context "with invalid api key" do
    let(:demo_key) { I18n.t('api.general.demo_key') }

    describe "POST /api/v1/#{model_name.pluralize}" do
      it "returns 401" do
        get "/api/v1/#{model_name.pluralize}", headers: { "X-BIP-Api-Key" => "invalid" }

        expect(response.status).to eq 401
        expect(parsed_response['reason']).not_to be_empty
      end

      it "shows gentle reminder if one is using demo key" do
        get "/api/v1/#{model_name.pluralize}", headers: { "X-BIP-Api-Key" => demo_key }

        expect(response.status).to eq 401
        expect(parsed_response['reason']).to eq "Please use your own, personal API key"
      end
    end
  end

  context "with valid api key" do
    let(:api_key) { create(:api_key) }

    describe "POST /api/v1/#{model_name.pluralize}" do
      context "with valid attributes" do
        let(:model_attrs) {
          {}.tap do |attrs|
            required_attrs.each do |attr|
              if related_models.include? attr.to_s.gsub('_id','').to_sym
                # Special exception for PlantAccessions due to the fact that a PA cannot be linked both to PL and to PV
                if model_name == 'plant_accession' and attr == :plant_variety_id
                  attrs[attr] = nil
                else
                  attrs[attr] = create(attr.to_s.gsub('_id','')).id
                end
              elsif model_name == 'design_factor' && attr == :design_factors
                attrs[attr] = ["block_2", "row_V", "plot_354"]
              else
                attrs[attr] = "Foo"
              end
            end
            habtm_assocs.each do |assoc|
              attrs[assoc.param] = [
                create(assoc.klass.name.underscore.to_sym).id
              ]
            end
          end
        }

        it "creates an object" do
          expect {
            post "/api/v1/#{model_name.pluralize}", params: { model_name => model_attrs },
                                                    headers: { "X-BIP-Api-Key" => api_key.token }
          }.to change {
            model_klass.count
          }.by(1)

          expect(response).to be_success
          expect(parsed_response).to have_key(model_name)
          expect(model.klass.find(parsed_response[model_name]['id'])).to be_published
        end

        if Api.publishable_models.include?(model.klass)
          it "creates private object" do
            expect {
              post "/api/v1/#{model_name.pluralize}", params: { model_name => model_attrs.merge(published: false) },
                                                      headers: { "X-BIP-Api-Key" => api_key.token }
            }.to change {
              model_klass.count
            }.by(1)

            expect(response).to be_success
            expect(parsed_response).to have_key(model_name)
            expect(model.klass.find(parsed_response[model_name]['id'])).not_to be_published
          end
        end

        it "sets correct annotations" do
          post "/api/v1/#{model_name.pluralize}", params: { model_name => model_attrs },
                                                  headers: { "X-BIP-Api-Key" => api_key.token }

          expect(response).to be_success
          expect(parsed_response[model_name]['date_entered']).to eq Date.today.to_s
          expect(parsed_response[model_name]['entered_by_whom']).to eq api_key.user.full_name
          expect(parsed_response[model_name]['published']).to be_truthy
          expect(Time.parse(parsed_response[model_name]['published_on'])).
            to be_within(10.seconds).of(Time.now)
        end

        it "prevents user impersonating anyone or changing dates" do
          better_attrs = model_attrs.merge(
            :date_entered => Date.today - 3.days,
            :entered_by_whom => 'This was not me!'
          )
          post "/api/v1/#{model_name.pluralize}", params: { model_name => better_attrs },
                                                  headers: { "X-BIP-Api-Key" => api_key.token }

          expect(response).to be_success
          expect(parsed_response[model_name]['date_entered']).to eq Date.today.to_s
          expect(parsed_response[model_name]['entered_by_whom']).to eq api_key.user.full_name
        end

        it "assigns HABTM associations" do
          if habtm_assocs.present?
            post "/api/v1/#{model_name.pluralize}", params: { model_name => model_attrs },
                                                    headers: { "X-BIP-Api-Key" => api_key.token }

            expect(response).to be_success

            habtm_assocs.each do |assoc|
              expect(model_klass.last.send(assoc.name).pluck(assoc.primary_key)).
                to match_array(model_attrs[assoc.param])
            end
          end
        end
      end

      context "with lack of required params" do
        let(:model_attrs) {
          {}.tap do |attrs|
            required_attrs.each do |attr|
              attrs[attr] = ""
            end
          end
        }

        it "returns errors" do
          expect {
            post "/api/v1/#{model_name.pluralize}", params: { model_name => model_attrs },
                                                    headers: { "X-BIP-Api-Key" => api_key.token }
          }.not_to change {
            model_klass.count
          }

          expect(response.status).to eq 422
          expect(parsed_response).to have_key("errors")
          expect(parsed_response['errors'].first).
            to eq('attribute' => required_attrs.first.to_s, 'message' => "Can't be blank")
        end
      end

      context "with wrong foreign key params" do
        let(:model_attrs) {
          {}.tap do |attrs|
            required_attrs.each do |attr|
              attrs[attr] = "Foo"
            end
            related_models.each do |attr|
              if model_name == 'plant_accession' && attr.to_s == 'plant_variety'
                attrs["#{attr}_id"] = nil
              else
                attrs["#{attr}_id"] = 555555
              end
            end
          end
        }

        it "returns errors" do
          if related_models.present?
            expect {
              post "/api/v1/#{model_name.pluralize}", params: { model_name => model_attrs },
                                                      headers: { "X-BIP-Api-Key" => api_key.token }
            }.not_to change {
              model_klass.count
            }

            expect(response.status).to eq 422
            expect(parsed_response).to have_key("errors")
            attribute = parsed_response['errors']['attribute']
            expect(related_models).to include(attribute[0..-4].to_sym)
            expect(parsed_response['errors']['message']).
              to start_with "DETAIL:  Key (#{attribute})=(555555) is not present in table"
          end
        end
      end

      context "with misnamed params" do
        let(:model_attrs) {
          { foo: "bar" }
        }

        it "returns errors on wrong model attribute name" do
          expect {
            post "/api/v1/#{model_name.pluralize}", params: { model_name => model_attrs }, headers: { "X-BIP-Api-Key" => api_key.token }
          }.not_to change {
            model_klass.count
          }

          expect(response.status).to eq 422
          expect(parsed_response).to have_key("errors")
          expect(parsed_response['errors'].first).
            to eq('attribute' => 'foo', 'message' => 'Unrecognized attribute name')
        end

        it "returns error on wrong model name" do
          expect {
            post "/api/v1/#{model_name.pluralize}", params: { "wrong_name" => { "does" => "not matter" } },
                                                    headers: { "X-BIP-Api-Key" => api_key.token }
          }.not_to change {
            model_klass.count
          }

          expect(response.status).to eq 422
          expect(parsed_response).to have_key("errors")
          expect(parsed_response['errors']).
            to eq('attribute' => model_name, 'message' => "param is missing or the value is empty: #{model_name}")
        end
      end
    end
  end

  def required_attributes(model_klass)
    presence_validators = model_klass.validators.select do |v|
      v.instance_of? ActiveRecord::Validations::PresenceValidator
    end
    presence_validators.map(&:attributes).flatten.uniq
  end
end
