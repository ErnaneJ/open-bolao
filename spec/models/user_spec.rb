require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(100) }
    it { should validate_presence_of(:email) }
  end

  describe "enums" do
    it { should define_enum_for(:role).with_values(user: 0, admin: 1, super_admin: 2).with_prefix(:role) }
    it { should define_enum_for(:locale).with_values(pt_br: 0, en: 1) }
  end

  describe "#display_name" do
    it "returns name when present" do
      user = build(:user, name: "João")
      expect(user.display_name).to eq("João")
    end
  end

  describe "associations" do
    it { should have_many(:administered_pools).class_name("Pool") }
    it { should have_many(:pool_participants) }
    it { should have_many(:tips) }
    it { should have_many(:notifications) }
  end
end
