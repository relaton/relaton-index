describe Relaton::Index::Type do
  before { Relaton::Index.instance_variable_set(:@config, nil) }

  context "create Type" do
    it "with default filename" do
      file_io = double("file_io")
      # expect(file_io).to receive(:read).and_return :index
      expect(Relaton::Index::FileIO).to receive(:new).with("iso", :url, "index.yaml").and_return file_io
      idx = described_class.new(:ISO, :url)
      expect(idx.instance_variable_get(:@file_io)).to be file_io
      # expect(idx.instance_variable_get(:@index)).to be :index
    end

    it "with custom filename" do
      file_io = double("file_io")
      # expect(file_io).to receive(:read).and_return :index
      expect(Relaton::Index::FileIO).to receive(:new).with("iso", :url, :file).and_return file_io
      idx = described_class.new(:ISO, :url, :file)
      expect(idx.instance_variable_get(:@file_io)).to be file_io
      # expect(idx.instance_variable_get(:@index)).to be :index
    end
  end

  context "instace methods" do
    let(:index) { [{ id: "id1", file: "file1" }] }
    let(:file_io) { double("file_io", read: index) }

    subject do
      expect(Relaton::Index::FileIO).to receive(:new).with("iso", :url, "index.yaml").and_return file_io
      described_class.new(:ISO, :url, "index.yaml")
    end

    context "#actual?" do
      it "no url and file" do
        expect(subject.actual?).to be true
      end

      it "new url" do
        expect(file_io).to receive(:url).and_return :old
        expect(subject.actual?(url: :new)).to be false
      end

      it "new file" do
        expect(subject.actual?(file: :new)).to be false
      end

      it "same url and file" do
        expect(file_io).to receive(:url).and_return :url
        expect(subject.actual?(url: :url, file: "index.yaml")).to be true
      end
    end

    context "#add_or_update" do
      it "add" do
        subject.add_or_update "id2", "file2"
        expect(index).to eq [{ id: "id1", file: "file1" }, { id: "id2", file: "file2" }]
      end

      it "update" do
        subject.add_or_update "id1", "file2"
        expect(index).to eq [{ id: "id1", file: "file2" }]
      end
    end

    context "#search" do
      before { index << { id: "id2", file: "file2" } }

      it "withou block" do
        expect(subject.search("id2")).to eq [{ id: "id2", file: "file2" }]
      end

      it "with block" do
        expect(subject.search { |i| i[:id] == "id1" }).to eq [{ id: "id1", file: "file1" }]
      end
    end

    it "#save" do
      expect(file_io).to receive(:save).with(index)
      subject.instance_variable_set(:@index, index)
      subject.save
    end

    it "#remove" do
      expect(file_io).to receive(:remove)
      subject.remove
    end

    it "#remove_all" do
      subject.remove_all
      index = subject.instance_variable_get(:@index)
      expect(index).to eq []
    end
  end
end
