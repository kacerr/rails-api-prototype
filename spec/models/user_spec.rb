require 'rails_helper'

describe User do
  subject { FactoryGirl.build(:user) }

  it "is not valid when email is not present" do
    subject.email = ""
    expect(subject).not_to be_valid
  end

  it "is valid user object" do
    expect(subject).to be_valid
  end


  it "responds to its attributes" do 
    expect(subject).to respond_to(:email)
    expect(subject).to respond_to(:password)
    expect(subject).to respond_to(:password_confirmation)
    expect(subject).to respond_to(:auth_token)
  end

  it { should validate_uniqueness_of(:auth_token)}

  describe "#generate_authentication_token!" do
    it "generates a unique token" do
      allow(Devise).to receive(:friendly_token).and_return("auniquetoken123")
      subject.generate_authentication_token!
      expect(subject.auth_token).to eql "auniquetoken123"
    end

    it "generates another token when one already has been taken" do
      existing_user = FactoryGirl.create(:user, auth_token: "auniquetoken123")
      subject.generate_authentication_token!
      expect(subject.auth_token).not_to eql existing_user.auth_token
    end
  end
  
end
