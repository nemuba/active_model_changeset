# frozen_string_literal: true

RSpec.describe ActiveModelChangeset do
  it "has a version number" do
    expect(described_class::VERSION).not_to be_nil
  end

  it "provides Base class" do
    expect(described_class::Base).to be_a(Class)
  end

  it "provides Changeset alias for backwards compatibility" do
    expect(described_class::Changeset).to eq(described_class::Base)
  end
end
