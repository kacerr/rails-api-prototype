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
  end

  
end
