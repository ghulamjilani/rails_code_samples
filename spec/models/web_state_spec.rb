require 'spec_helper'

describe WebState do

  it { should belong_to :current_week }

  it "does not allow you to have more than 1 WebState record" do
    season = FactoryGirl.create(:season)
    week_1 = FactoryGirl.create(:week, week_number: 10, season: season)
    week_2 = FactoryGirl.create(:week, week_number: 11, season: season)

    ws = WebState.new()
    ws.current_week = week_1
    ws.current_season = season
    ws.save!
    expect(WebState.count).to eq(1)

    ws_nogo = WebState.new()
    ws.current_week = week_2
    ws.current_season = season
    ws.save!
    expect(WebState.count).to eq(1)
  end

  describe '#season_matches_week' do
    before do
      @season_1 = FactoryGirl.create(:season)
      @week_1_season_1 = FactoryGirl.create(:week, week_number: 1, season: @season_1)
      @week_2_season_1 = FactoryGirl.create(:week, week_number: 2, season: @season_1)

      @season_2 = FactoryGirl.create(:season)
      @week_1_season_2 = FactoryGirl.create(:week, week_number: 1, season: @season_2)
      @week_2_season_2 = FactoryGirl.create(:week, week_number: 2, season: @season_2)

      ws = WebState.new()
      ws.current_week = @week_1_season_1
      ws.current_season = @season_1
      ws.save!
    end

    it 'allows you to move to a new week in the same season' do
      @web_state = WebState.first
      @web_state.current_week = @week_2_season_1
      expect(@web_state.valid?).to eql true
    end

    it 'stops you from moving to a week in a different season' do
      @web_state = WebState.first
      @web_state.current_week = @week_2_season_2
      expect(@web_state.valid?).to eql false
    end
  end
end
