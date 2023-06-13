describe Relaton::Index::Pool do
  it "create Pool" do
    expect(subject.instance_variable_get(:@pool)).to eq({})
  end

  context "instace methods" do
    context "#type" do
      let(:idx) { double("idx") }
      before do
        expect(Relaton::Index::Type).to receive(:new).with("ISO", :url, :file, :keys).and_return idx
      end

      it "create new Type" do
        expect(subject.type("ISO", url: :url, file: :file, id_keys: :keys)).to be idx
      end

      it "return existing Type" do
        expect(idx).to receive(:actual?).with(url: :url, file: :file).and_return true
        subject.type("ISO", url: :url, file: :file, id_keys: :keys)
        expect(subject.type(:ISO, url: :url, file: :file)).to be idx
      end
    end

    it "#remove" do
      subject.instance_variable_set(:@pool, { ISO: :idx })
      subject.remove :ISO
      expect(subject.instance_variable_get(:@pool)).to eq({})
    end
  end
end
