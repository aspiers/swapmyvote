require "spec_helper"
require_relative "../../app/lib/app_modes"

RSpec.describe AppModes do
  specify ".all returns an Array of 5 valid modes" do
    expect(subject.all).to be_an(Array)
    expect(subject.all.count).to be(5)
  end

  specify "stringify converts a symbol mode into a string" do
    expect(subject.stringify(:foo_bar)).to eq("foo-bar")
  end

  specify "symbolize converts a string mode into a symbol" do
    expect(subject.symbolize("foo-bar")).to eq(:foo_bar)
  end
end
