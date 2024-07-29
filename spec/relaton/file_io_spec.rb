require "uri"

describe Relaton::Index::FileIO do
  it "create FileIO" do
    fio = described_class.new("iso", :url, :filename, nil)
    expect(fio.instance_variable_get(:@dir)).to eq "iso"
    expect(fio.instance_variable_get(:@url)).to eq :url
    expect(fio.instance_variable_get(:@filename)).to eq :filename
  end

  context "instace methods" do
    subject do
      subj = described_class.new("iso", nil, "index.yaml", nil, pubid_class)
      subj.instance_variable_set(:@file, "index.yaml")
      subj
    end
    let(:pubid_class) { TestIdentifier }

    context "#deserialize_pubid" do
      subject { described_class.new("iso", nil, "index.yaml", nil, pubid_class).deserialize_pubid(index) }
      let(:index) { [{ id: { publisher: "ISO", number: 1 } }] }

      it "deserealizes pubid objects" do
        expect(subject.first[:id]).to eq(TestIdentifier.create(publisher: "ISO", number: 1))
      end

      context "when pubid_class is not specified" do
        let(:pubid_class) { nil }

        it "returns original index values" do
          expect(subject.first[:id]).to eq(index.first[:id])
        end
      end
    end

    context "#read" do
      it "without url" do
        fio = described_class.new("iso", nil, "index.yaml", nil)
        expect(fio).to receive(:read_file).and_return :index
        expect(fio.read).to be :index
      end

      context "with url" do
        subject { described_class.new("iso", "url", "index.yaml", nil) }

        it "index file exists and actual" do
          expect(subject).to receive(:check_file).and_return :index
          expect(subject.read).to be :index
        end

        it "index file doesn't exist or not actual" do
          expect(subject).to receive(:check_file).and_return nil
          expect(subject).to receive(:fetch_and_save).and_return :index
          expect(subject.read).to be :index
        end
      end

      it "fails to read file" do
        subject.instance_variable_set(:@url, true)
        expect(subject).to receive(:read_file).and_return nil
        expect(subject.read).to eq []
      end
    end

    context "#check_file" do
      it "index file doesn't exist" do
        expect(Relaton::Index::FileStorage).to receive(:ctime).with("index.yaml").and_return nil
        expect(subject).not_to receive(:read_file)
        expect(subject.check_file).to be nil
      end

      it "index file not actual" do
        expect(Relaton::Index::FileStorage).to receive(:ctime).with("index.yaml").and_return Time.now - 86400
        expect(subject).not_to receive(:read_file)
        expect(subject.check_file).to be nil
      end

      it "index file exists and actual" do
        expect(Relaton::Index::FileStorage).to receive(:ctime).with("index.yaml").and_return Time.now
        expect(subject).to receive(:read_file).and_return :index
        expect(subject.check_file).to be :index
      end
    end

    context "#check_basic_format" do
      it "correct" do
        index = [{ file: "data/1.yaml", id: { type: "TR", number: "1234" } }]
        expect(subject.check_basic_format(index)).to be true
      end

      it "incorrect" do
        index = [{ id: "1234" }]
        expect(subject.check_basic_format(index)).to be false
      end

      it "index is not array" do
        expect(subject.check_basic_format(nil)).to be false
      end
    end

    context "#fetch_and_save" do
      before do
        subject.instance_variable_set(:@url, "url")

        zipped = File.binread("spec/assets/index1.zip")
        expect_any_instance_of(URI::Generic).to receive(:read)
          .and_return(zipped)
      end

      it "success" do
        index = [{ file: "data/1.yaml", id: 1 }]
        expect(subject).to receive(:save).with(index)
        expect do
          expect(subject.fetch_and_save).to eq index
        end.to output(/Downloaded index from url/).to_stderr
      end

      it "wrong index structure" do
        expect(subject).to receive(:check_format).and_return false
        expect do
          expect(subject.fetch_and_save).to be_nil
        end.to output(/Wrong structure of newly downloaded file/).to_stderr
      end

      it "fails to parse yaml" do
        expect(YAML).to receive(:safe_load).and_raise Psych::SyntaxError.new("", 1, 1, 0, nil, nil)
        expect do
          expect(subject.fetch_and_save).to be_nil
        end.to output(/YAML parsing error when reading newly downloaded file/).to_stderr
      end
    end

    context "#read_file" do
      it "file doesn't exist" do
        expect(Relaton::Index::FileStorage).to receive(:read).with("index.yaml").and_return nil
        expect(YAML).not_to receive(:safe_load)
        expect(subject.read_file).to be_nil
      end

      it "file exists" do
        yaml = [{ file: "data/1.yaml", id: { publisher: "ISO", number: 1 } }].to_yaml
        expect(Relaton::Index::FileStorage).to receive(:read).with("index.yaml").and_return yaml
        expect(subject.read_file).to eq [{ file: "data/1.yaml", id: TestIdentifier.create(publisher: "ISO", number: 1) }]
      end

      it "fail to load yaml" do
        wrong_yaml = "---\n- :id: :file: data/1.yaml\n"
        expect(Relaton::Index::FileStorage).to receive(:read).with("index.yaml").and_return wrong_yaml
        expect do
          expect(subject.read_file).to eq []
        end.to output(/\[relaton-iso\] YAML parsing error when reading file index\.yaml/).to_stderr
      end

      it "wrong index structure" do
        wrong_yaml = "---\n- :id: 1\n  :fl: data/1.yaml\n"
        expect(Relaton::Index::FileStorage).to receive(:read).with("index.yaml").and_return wrong_yaml
        expect do
          expect(subject.read_file).to eq []
        end.to output(/\[relaton-iso\] Wrong structure of the file/).to_stderr
      end
    end

    context "#warn_local_index_error" do
      it "URL is set" do
        subject.instance_variable_set(:@url, "url")
        expect do
          expect(subject.warn_local_index_error("")).to be_nil
        end.to output(/\[relaton-iso\] Considering index\.yaml file corrupt, re-downloading from url/).to_stderr
      end

      it "URL is not set" do
        expect(subject).to receive(:remove).and_return []
        expect do
          expect(subject.warn_local_index_error("")).to eq []
        end.to output(/\[relaton-iso\] Considering index\.yaml file corrupt, removing it/).to_stderr
      end
    end

    context "#check_format" do
      let(:index) { [{ file: "data/1.yaml", id: { type: "TR", number: "1234" } }] }

      it "correct with id_keys" do
        subject.instance_variable_set(:@id_keys, %i[type number year])
        expect(subject.check_format(index)).to be true
      end

      it "incorrect with id_keys" do
        subject.instance_variable_set(:@id_keys, %i[number year])
        expect(subject.check_format(index)).to be false
      end

      it "correct without id_keys" do
        expect(subject.check_format(index)).to be true
      end

      it "incorrect without id_keys" do
        index = [{ id: "1234" }]
        expect(subject.check_format(index)).to be false
      end

      it "incorrect type" do
        index = [:id]
        expect(subject.check_format(index)).to be false
      end
    end

    context "#save" do
      it do
        expect(Relaton::Index::FileStorage).to receive(:write).with("index.yaml", "---\n- :id:\n    :publisher: ISO\n    :number: '1'\n  :file: data/1.yaml\n")
        subject.save [{ id: TestIdentifier.create(publisher: "ISO", number: 1), file: "data/1.yaml" }]
      end
    end

    it "#remove" do
      expect(Relaton::Index::FileStorage).to receive(:remove).with("index.yaml")
      subject.remove
    end
  end
end
