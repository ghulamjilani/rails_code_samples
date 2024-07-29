# frozen_string_literal: true

class MadrassasController < ApplicationController
  before_action :authenticate_user!, except: [:madrassas_against_region]
  before_action :set_madrassa, only: %i[update destroy]
  load_and_authorize_resource except: [:madrassas_against_region, :classes_of_madrassa]

  def index
    @madrassas = current_user.super_admin? ? all_madrassas : current_user.region.madrassas
    @madrassas = filtered_madrassas if params[:region_id].present?
    @madrassas = @madrassas.page(params[:page])
  end

  def create
    @madrassa = Madrassa.new(madrassa_params)
    return redirect_to madrassas_url, notice: 'Madrassa was successfully created.' if @madrassa.save

    redirect_to madrassas_url, alert: @madrassa.errors.full_messages.join(', ')
  end

  def update
    return redirect_to madrassas_url, notice: 'Madrassa was successfully updated.' if @madrassa.update(madrassa_params)

    redirect_to madrassas_url, alert: @madrassa.errors.full_messages.join(', ')
  end

  def destroy
    return redirect_to madrassas_url, notice: 'Madrassa was successfully deleted.' if @madrassa.destroy

    redirect_to madrassas_url, alert: 'Failed to delete Madrassa.'
  end

  def madrassas_against_region
    return render json: Madrassa.all unless params[:id].present?

    region = Region.find_by_id(params[:id])
    madrassas = region.madrassas
    madrassas = madrassas.where(kind: params[:type]) if params[:type].present?

    render json: madrassas
  end

  def classes_of_madrassa
    return render json: [] if params[:is_form] && params[:is_form].eql?('true')

    return render json: Standard.all unless params[:id].present?

    madrassa = Madrassa.find_by_id(params[:id])
    classes = madrassa.classes
    render json: classes
  end

  private

  def all_madrassas
    Madrassa.all.order(created_at: :desc)
  end

  def filtered_madrassas
    @madrassas.where(region_id: params[:region_id]).order(created_at: :desc)
  end

  def madrassa_params
    params.require(:madrassa).permit(:name, :address, :phone_no, :region_id, :post_code, :kind)
  end

  def set_madrassa
    @madrassa = Madrassa.find_by(id: params[:id].to_i)
  end
end
