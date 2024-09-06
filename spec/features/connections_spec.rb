require 'rails_helper'

RSpec.feature "Connections::Connections", type: :feature do
  let(:user) { create(:user, verification_code_correct: true) }
  before { sign_in_user(user) }

  describe 'Pending Connections' do
    let!(:pending_connection) { create(:connection, friend_id: user.id) }
    before do
      visit connections_path
      click_link 'Pending Connections'
    end

    it 'user can approve connection' do
      click_link 'Connect'
      expect(page).to have_content("#{pending_connection.user.full_name} is now a connection")
      expect(page).to have_link('Message')
    end

    it 'user can reject a pending connection' do
      accept_confirm('Are you sure?') do
        click_link 'Reject'
      end
      expect(page).to have_content('Connection was successfully destroyed.')
    end
  end

  describe 'Active Connections' do
    let!(:active_connection) { create(:connection, friend_id: user.id, confirmed: true) }
    before do
      visit connections_path
      find('#activeConnectionActionBtn').click
    end

    it 'user can remove active connection' do
      accept_confirm('Are you sure you want to remove this connection?') do
        click_link 'Remove'
      end
      expect(page).to have_content('Connection was successfully destroyed.')
    end
  end
end
