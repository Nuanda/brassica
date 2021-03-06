require 'rails_helper'

RSpec.describe Searchable do
  describe '.indexed_json_structure' do
    it 'returns proper json structure' do
      # Chosen three examples
      proper = {
        only: [
          :map_position
        ],
        include: {
          marker_assay: { only: [:marker_assay_name] },
          population_locus: { only: [:mapping_locus] },
          linkage_group: { only: [:linkage_group_label] }
        }
      }
      expect(MapPosition.indexed_json_structure).to eq proper

      proper = {
        only: [
          :consensus_group_assignment,
          :canonical_marker_name,
          :associated_sequence_id,
          :sequence_source_acronym,
          :atg_hit_seq_id,
          :atg_hit_seq_source,
          :bac_hit_seq_id,
          :bac_hit_seq_source,
          :bac_hit_name
        ],
        include: {
          map_position: { only: [:map_position] }
        }
      }
      expect(MapLocusHit.indexed_json_structure).to eq proper

      proper = {
        only: [
          :plant_line_name,
          :common_name,
          :previous_line_name,
          :genetic_status,
          :sequence_identifier,
          :data_owned_by,
          :organisation
        ],
        include: {
          taxonomy_term: { only: [:name] },
          plant_variety: { only: [:plant_variety_name] }
        }
      }
      expect(PlantLine.indexed_json_structure).to eq proper
    end
  end

  describe "callbacks" do
    let(:es) { PlantLine.__elasticsearch__.client }
    let(:index) { PlantLine.index_name }

    context "after create", :elasticsearch do
      let!(:published_plant_line) { create(:plant_line, published: true) }
      let!(:unpublished_plant_line) { create(:plant_line, published: false) }

      it "indexes record on creation if published" do
        expect(es.exists(id: published_plant_line.id, index: index)).to be_truthy
      end

      it "does not index record on creation if not published" do
        expect(es.exists(id: unpublished_plant_line.id, index: index)).to be_falsey
      end
    end

    context "after update", :elasticsearch do
      let!(:published_plant_line) { create(:plant_line, published: true, data_owned_by: "Batz and Sons") }
      let!(:unpublished_plant_line) { create(:plant_line, published: false) }

      it "indexes record" do
        unpublished_plant_line.update_attribute(:published, true)

        expect(es.exists(id: published_plant_line.id, index: index)).to be_truthy
      end

      it "removes record from index" do
        published_plant_line.update_attribute(:published, false)

        expect(es.exists(id: published_plant_line.id, index: index)).to be_falsey
      end

      it "does not remove unpublished, updated record" do
        expect {
          unpublished_plant_line.update_attribute(:comments, 'some text')
        }.not_to raise_error
      end

      it "updates published, updated record" do
        expect {
          published_plant_line.update_attribute(:data_owned_by, 'The Great Data Owner')
        }.to change {
          es.get(id: published_plant_line.id, index: index)["_source"]["data_owned_by"]
        }.
        from("Batz and Sons").to("The Great Data Owner")

        expect(es.exists(id: published_plant_line.id, index: index)).to be_truthy
      end
    end

    context "after destroy", :elasticsearch do
      let!(:published_plant_line) { create(:plant_line, published: true) }
      let!(:unpublished_plant_line) { create(:plant_line, published: false) }

      it "removes record from index" do
        published_plant_line.destroy
        unpublished_plant_line.destroy

        expect(es.exists(id: published_plant_line.id, index: index)).to be_falsey
        expect(es.exists(id: unpublished_plant_line.id, index: index)).to be_falsey
      end
    end
  end
end
