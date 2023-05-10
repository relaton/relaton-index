describe Relaton::Index::FileIO do
  it "create FileIO" do
    fio = described_class.new("iso", :url, :filename)
    expect(fio.instance_variable_get(:@dir)).to eq "iso"
    expect(fio.instance_variable_get(:@url)).to eq :url
    expect(fio.instance_variable_get(:@filename)).to eq :filename
  end

  context "instace methods" do
    subject do
      subj = described_class.new("iso", nil, "index.yaml")
      subj.instance_variable_set(:@file, "index.yaml")
      subj
    end

    context "#read" do
      it "without url" do
        fio = described_class.new("iso", nil, "index.yaml")
        expect(fio).to receive(:read_file).and_return :index
        expect(fio.read).to be :index
        expect(fio.instance_variable_get(:@file)).to eq "index.yaml"
      end

      context "with url" do
        let(:file) { File.join(Dir.home, ".relaton", "iso", "index.yaml") }
        subject { described_class.new("iso", :url, "index.yaml") }

        it "index file exists and actual" do
          expect(subject).to receive(:check_file).and_return :index
          expect(subject.read).to be :index
          expect(subject.instance_variable_get(:@file)).to eq file
        end

        it "index file doesn't exist or not actual" do
          expect(subject).to receive(:check_file).and_return nil
          expect(subject).to receive(:fetch_and_save).and_return :index
          expect(subject.read).to be :index
          expect(subject.instance_variable_get(:@file)).to eq file
        end
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

    it "#fetch_and_save" do
      subject.instance_variable_set(:@url, "url")
      uri = double("uri")
      expect(uri).to receive(:open).and_return :resp
      expect(URI).to receive(:parse).with("url").and_return uri
      entry = double("entry")
      yaml = "---\n- :id: 1\n  :file: data/1.yaml\n"
      expect(entry).to receive_message_chain(:get_input_stream, :read).and_return yaml
      zip = double("zip")
      expect(zip).to receive(:get_next_entry).and_return entry
      expect(Zip::InputStream).to receive(:new).with(:resp).and_return zip
      index = [{ file: "data/1.yaml", id: 1 }]
      expect(subject).to receive(:save).with(index)
      expect(subject.fetch_and_save).to eq index
    end

    context "#read_file" do
      it "file doesn't exist" do
        expect(Relaton::Index::FileStorage).to receive(:read).with("index.yaml").and_return nil
        expect(YAML).not_to receive(:load)
        expect(subject.read_file).to eq []
      end

      it "file exists" do
        yaml = "---\n- :id: 1\n  :file: data/1.yaml\n"
        expect(Relaton::Index::FileStorage).to receive(:read).with("index.yaml").and_return yaml
        expect(subject.read_file).to eq [{ file: "data/1.yaml", id: 1 }]
      end
    end

    it "#save" do
      expect(Relaton::Index::FileStorage).to receive(:write).with("index.yaml", "---\n- :id: '1'\n  :file: data/1.yaml\n")
      subject.save [{ id: "1", file: "data/1.yaml" }]
    end

    it "#remove" do
      expect(Relaton::Index::FileStorage).to receive(:remove).with("index.yaml")
      subject.remove
    end
  end
end
