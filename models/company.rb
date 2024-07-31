class Company < ApplicationRecord
  include Managers_users

  extend FriendlyId
  acts_as_followable
  serialize :address, Array
  serialize :skill, Array
  has_one_attached :logo
  has_one_attached :banner
  friendly_id :name, use: :slugged
  has_many :pictures, as: :imageable, dependent: :destroy
  has_many :page_views, as: :viewable, dependent: :destroy
  has_many :company_users, dependent: :destroy
  has_many :users, through: :company_users
  belongs_to :state, optional: true
  accepts_nested_attributes_for :pictures, allow_destroy: true
  has_many :company_therapeutic_focus, dependent: :destroy
  has_many :therapeutic_focus, through: :company_therapeutic_focus
  has_many :announcements, as: :announcementable, dependent: :destroy
  has_many :events, as: :eventable, dependent: :destroy
  has_many :webinars, as: :webinarable, dependent: :destroy
  has_many :organization_documents, dependent: :destroy
  belongs_to :city, optional: true
  has_many :jobs, as: :jobable, dependent: :destroy
  has_many :manager_users, as: :manageable, dependent: :destroy
  has_many :attachments, as: :attachable, dependent: :destroy
  has_many :rankings_given, class_name: "Ranking", as: :rankable_by
  has_many :rankings_received, class_name: "Ranking", as: :rankable_to
  has_one :calendar_setting, as: :settingable, dependent: :destroy
  validate :media_fields_presence

  accepts_nested_attributes_for :attachments, allow_destroy: true
  validates_associated :attachments
  before_save :attachment_purge
  scope :not_current, ->(company_id) { where.not(id: company_id) }
  scope :filter_by_name, ->(name) { where('name ILIKE ?', "%#{name}%") }
  scope :profile_view_users, ->(days_count, type, views) { joins(:page_views).where(page_views: { id: views.ids, created_at: days_count.send(type).ago.beginning_of_day..Date.today.end_of_day }).uniq }

  def should_generate_new_friendly_id?
    slug.blank? || name_changed?
  end

  def therapeutic_focu_ids=(ids)
    self.therapeutic_focus = TherapeuticFocu.find(ids.compact_blank)
  end

  def video
    attachments&.last&.video
  end

  def save_images
    params[:company][:pictures_attributes]['0']['image'].each do |image|
      pictures.create(image: image)
    end
  end

  def update_image(params)
    pictures.create(image: params[:company][:pictures_attributes]['0']['image'])
  end

  def remove_image
    params[:pictures].each do |picture|
      Picture.find(picture.last[:id]).destroy if picture.last[:_destroy] == 'on'
    end
  end

  def attachment_purge
    return unless attachments.any?(&:changed?)

    attachments.map { |attachment| attachment.destroy if attachment.id.present? }
  end

  def add_company_user(current_user_id, user_id, status = 'approved')
    company_users.create(user_id: user_id, status: status)
    return unless status == 'approved'
  end

  def company_admin_user?(user_id)
    company_users.where('role = ? AND user_id = ? AND status = ?', CompanyUser.roles[:admin], user_id,CompanyUser.statuses[:approved]).present?
  end

  def company_manager_user?(user_id)
    company_users.where('role = ? AND user_id = ? AND status = ?', CompanyUser.roles[:manager], user_id,CompanyUser.statuses[:approved]).present?
  end

  def manager_admin_user?(user_id)
    manager_users.where('user_id = ? AND status = ?', user_id,ManagerUser.statuses[:admin]).present?
  end

  private

  def media_fields_presence
    unless video.present? || video_link.present? || vimeo_link.present?
      errors.add(:base, "At least Video, YouTube, or Vimeo must be present")
    end
  end
end
