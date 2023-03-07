describe Relaton::Index::Type do
  it "create Type" do
    file_io = double("file_io")
    expect(file_io).to receive(:read).and_return :index
    expect(Relaton::Index::FileIO).to receive(:new).with("iso", :url).and_return file_io
    idx = described_class.new(:ISO, :url)
    expect(idx.instance_variable_get(:@file_io)).to be file_io
    expect(idx.instance_variable_get(:@index)).to be :index
  end

  context "instace methods" do
    let(:index) { [{ id: "id1", file: "file1" }] }
    let(:file_io) { double("file_io", read: index) }

    subject do
      expect(Relaton::Index::FileIO).to receive(:new).with("iso", :url).and_return file_io
      described_class.new(:ISO, :url)
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
        expect(subject.search("id2") { |i| i[:id] == "id1" }).to eq [{ id: "id1", file: "file1" }]
      end
    end

    it "#save" do
      expect(file_io).to receive(:save).with(index)
      subject.save
    end
  end
end
