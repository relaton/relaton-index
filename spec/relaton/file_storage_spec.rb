describe Relaton::Index::FileStorage do
  context "#ctime" do
    it "file does not exist" do
      expect(File).to receive(:exist?).with("index.yaml").and_return false
      expect(described_class.ctime("index.yaml")).to be false
    end

    it "file exists" do
      expect(File).to receive(:exist?).with("index.yaml").and_return true
      expect(File).to receive(:ctime).with("index.yaml").and_return :time
      expect(described_class.ctime("index.yaml")).to eq :time
    end

    context "#read" do
      it "file does not exist" do
        expect(File).to receive(:exist?).with("index.yaml").and_return false
        expect(described_class.read("index.yaml")).to be nil
      end

      it "file exists" do
        expect(File).to receive(:exist?).with("index.yaml").and_return true
        expect(File).to receive(:read).with("index.yaml", encoding: "UTF-8").and_return :data
        expect(described_class.read("index.yaml")).to eq :data
      end
    end

    it "#write" do
      expect(File).to receive(:write).with("index.yaml", :data, encoding: "UTF-8")
      described_class.write("index.yaml", :data)
    end
  end
end
