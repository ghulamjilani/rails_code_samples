require 'rails_helper'

RSpec.describe Api::V1::LoanOffersController, type: :controller do
  # let!(:loan_offers) { create_list(:loan_offer, 10) }
  # let(:loan_offer_id) { loan_offers.first.id }
  login_user

  describe 'GET #index' do
    it 'gets applied loan offers for current user' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    it 'create a loan record' do
      post :create, format: :json, params: {
        loan_offer: {
          loan_amount: 3,
          amount_deduction_type: 'month',
          amount_deduction_value: 1,
          total_fees: 1,
          amount_per_installment: 1,
          loan_type: 'car'
        }
      }
      expect(response).to have_http_status(:success)
      expect(LoanOffer.count).to eq(1)
    end
  end

  describe 'GET #show/:id' do
    before(:each) do
      @loan = create(:loan_offer)
    end
    it 'show details' do
      get :show, params: {id: @loan.id}
      expect(response).to have_http_status(:success)
    end
  end
end
