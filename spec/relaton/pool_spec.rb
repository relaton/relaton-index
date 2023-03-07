describe Relaton::Index::Pool do
  it "create Pool" do
    expect(subject.instance_variable_get(:@pool)).to eq({})
  end

  context "instace methods" do
    it "#type" do
      expect(Relaton::Index::Type).to receive(:new).with("ISO", :url).and_return :idx
      expect(subject.type("ISO", :url)).to be :idx
    end

    it "#remove" do
      subject.instance_variable_set(:@pool, { ISO: :idx })
      subject.remove :ISO
      expect(subject.instance_variable_get(:@pool)).to eq({})
    end
  end
end
