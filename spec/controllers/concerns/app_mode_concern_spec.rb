require "rails_helper"

require_relative "../../../app/controllers/concerns/app_mode_concern"

RSpec.describe AppModeConcern, type: :controller do
  include described_class
  include Devise::Test::ControllerHelpers

  let(:session) { {} }
  # let(:session) { double(ActionDispatch::Session) }

  describe "#app_mode" do
    it "defaults to open" do
      ENV.delete("SWAPMYVOTE_MODE")
      expect(app_mode).to eq("open")
    end

    it "is controlled by an environment variable" do
      ENV["SWAPMYVOTE_MODE"] = "closed-warm-up"
      expect(app_mode).to eq("closed-warm-up")
    end

    it "errors if environment variable has an invalid mode" do
      ENV["SWAPMYVOTE_MODE"] = "closed"
      expect {app_mode }
        .to raise_error \
              "Invalid SWAPMYVOTE_MODE value 'closed'; should be one of: #{AppModes::VALID_MODES}"
    end

    it "is controlled by a session parameter" do
      ENV.delete("SWAPMYVOTE_MODE")
      session[:sesame] = "closed-wind-down"
      expect(app_mode).to eq("closed-wind-down")
    end

    it "is controlled by a session parameter overriding environment" do
      ENV["SWAPMYVOTE_MODE"] = "open"
      session[:sesame] = "closed-wind-down"
      expect(app_mode).to eq("closed-wind-down")
    end
  end

  describe "#swapping_open?" do
    it "returns true when mode is open" do
      ENV["SWAPMYVOTE_MODE"] = "open"
      expect(swapping_open?).to be_truthy
    end

    it "returns false when mode is closed" do
      ENV["SWAPMYVOTE_MODE"] = "closed-warm-up"
      expect(swapping_open?).to be_falsey
    end
  end

  describe "#voting_open?" do
    it "returns true when voting is open" do
      ENV["SWAPMYVOTE_MODE"] = "open-and-voting"
      expect(voting_open?).to be_truthy
    end

    it "returns false when voting is closed" do
      ENV["SWAPMYVOTE_MODE"] = "open"
      expect(voting_open?).to be_falsey
    end
  end

  describe "#voting_info_locked?" do
    it "returns false when voting is closed" do
      ENV["SWAPMYVOTE_MODE"] = "open"
      expect(voting_info_locked?).to be_falsey
    end

    describe "when not logged in" do
      before do
        sign_in create(:user)
      end

      it "returns false when voting is closed" do
        ENV["SWAPMYVOTE_MODE"] = "open"
        expect(voting_info_locked?).to be_falsey
      end
    end
  end
end
