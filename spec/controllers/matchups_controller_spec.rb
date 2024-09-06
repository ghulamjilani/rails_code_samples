require 'spec_helper'

describe MatchupsController do
	describe "POST save_outcome" do

		before do
			@admin = create(:admin)
			sign_in :admin, @admin

			@season = Season.create(year: 2014, name: "2014 Season", entry_fee: 50)
			@week = Week.create(season: @season, week_number: 1, start_date: DateTime.new(2014, 8, 5), deadline: DateTime.new(2014, 8, 8), end_date: DateTime.new(2014, 8, 11))
			@pool_entry = PoolEntry.create!(user: @admin, team_name: "Test Team", paid: true, season: @season)

			@broncos = NflTeam.create(name: "Denver Broncos", conference: "NFC", division: "West")
			@vikings = NflTeam.create(name: "Minnesota Vikings", conference: "NFC", division: "North")
			@matchup = Matchup.create(week_id: @week.id, home_team: @broncos, away_team: @vikings, game_time: DateTime.new(2014,8,10,11))

			set_auth_headers(@admin)
		end

		context "game ends in a tie" do

			it "knocks out the pool entry" do
				@pick = Pick.create(pool_entry: @pool_entry, week: @week, team_id: @vikings.id, matchup: @matchup)
				@matchup.update_attributes(tie: true)
				post :save_outcome, week_id: @week.id, matchup: @matchup, format: :json
				@pool_entry.reload
				expect(@pool_entry.knocked_out).to eq(true)
			end

			it "completes the matchup" do
				@pick = Pick.create(pool_entry: @pool_entry, week: @week, team_id: @vikings.id, matchup: @matchup)
				@matchup.update_attributes(tie: true)
				post :save_outcome, week_id: @week.id, matchup: @matchup, format: :json
				@matchup.reload
				expect(@matchup.completed).to eq(true)
			end

			it "sets knocked_out_week_id for the pool_entry to this week" do
				@pick = Pick.create(pool_entry: @pool_entry, week: @week, team_id: @vikings.id, matchup: @matchup)
				@matchup.update_attributes(tie: true)
				post :save_outcome, week_id: @week.id, matchup: @matchup, format: :json
				@pool_entry.reload
				expect(@pool_entry.knocked_out_week_id).to eq(@week.id)
			end

			it "completes the matchup even if there are no picks for that game" do
				@matchup.update_attributes(tie: true)
				post :save_outcome, week_id: @week.id, matchup: @matchup, format: :json
				@matchup.reload
				expect(@matchup.completed).to eq(true)
			end
		end

		context "one team wins" do

			it "knocks out a pool entry if the selected team loses" do
				@pick = Pick.create(pool_entry: @pool_entry, week: @week, team_id: @vikings.id, matchup: @matchup)
				@matchup.update_attributes(winning_team_id: @broncos.id)
				post :save_outcome, week_id: @week.id, matchup: @matchup, format: :json
				@pool_entry.reload
				expect(@pool_entry.knocked_out).to eq(true)
			end

			it "sets the knocked_out_week_id for the pool_entry if they are knocked out" do
				@pick = Pick.create(pool_entry: @pool_entry, week: @week, team_id: @vikings.id, matchup: @matchup)
				@matchup.update_attributes(winning_team_id: @broncos.id)
				post :save_outcome, week_id: @week.id, matchup: @matchup, format: :json
				@pool_entry.reload
				expect(@pool_entry.knocked_out_week_id).to eq(@week.id)
			end

			it "does not knock out a pool entry if the selected team wins" do
				@pick = Pick.create(pool_entry: @pool_entry, week: @week, team_id: @vikings.id, matchup: @matchup)
				@matchup.update_attributes(winning_team_id: @vikings.id)
				post :save_outcome, week_id: @week.id, matchup: @matchup, format: :json
				@pool_entry.reload
				expect(@pool_entry.knocked_out).to eq(false)
			end

			it "does not set a knocked_out_week_id if they didn't lose" do
				@pick = Pick.create(pool_entry: @pool_entry, week: @week, team_id: @vikings.id, matchup: @matchup)
				@matchup.update_attributes(winning_team_id: @vikings.id)
				post :save_outcome, week_id: @week.id, matchup: @matchup, format: :json
				@pool_entry.reload
				expect(@pool_entry.knocked_out_week_id).to eq(nil)
			end

			it "completes the matchup" do
				@pick = Pick.create(pool_entry: @pool_entry, week: @week, team_id: @vikings.id, matchup: @matchup)
				@matchup.update_attributes(winning_team_id: @broncos.id)
				post :save_outcome, week_id: @week.id, matchup: @matchup, format: :json
				@matchup.reload
				expect(@matchup.completed).to eq(true)
			end

			it "completes the matchup even if there are no picks for that game" do
				@matchup.update_attributes(winning_team_id: @broncos.id)
				post :save_outcome, week_id: @week.id, matchup: @matchup, format: :json
				@matchup.reload
				expect(@matchup.completed).to eq(true)
			end
		end
	end

	describe "DELETE destroy" do

		before do
			@admin = create(:admin)
			sign_in :admin, @admin

			@season = Season.create(year: 2014, name: "2014 Season", entry_fee: 50)
			@week = Week.create(season: @season, week_number: 1, start_date: DateTime.new(2014, 8, 5), deadline: DateTime.new(2014, 8, 8), end_date: DateTime.new(2014, 8, 11))
			@pool_entry = PoolEntry.create(user: @admin, team_name: "Test Team", paid: true)

			@broncos = NflTeam.create(name: "Denver Broncos", conference: "NFC", division: "West")
			@vikings = NflTeam.create(name: "Minnesota Vikings", conference: "NFC", division: "North")
			@matchup = Matchup.create(week_id: @week.id, home_team: @broncos, away_team: @vikings, game_time: DateTime.new(2014,8,10,11))
		end

		it "deletes the matchup if there are no picks associated with it" do
			#delete :destroy, week_id: @week.id, id: @matchup.id, format: :json
			#expect(Matchup.all.count).to eq(0)
		end

		it "does not delete the matchup if there are picks associated with it" do

		end
	end
end