class Event < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_paper_trail
  
  # Validations
  validates :name, presence: true

  # Enums
  enum event_type: { in_person: 0, virtual: 1 }
  enum status: {'pending': 0, 'approved': 1, 'rejected': 2}

  scope :research_centers, -> { where(eventable_type: 'ResearchCenter') }
  scope :companies, -> { where(eventable_type: 'Company') }
  scope :nih_institutes_and_centers, -> { where(eventable_type: 'NihInstitutesAndCenter') }
  scope :schools, -> { where(eventable_type: 'School') }
  scope :communities, -> { where(eventable_type: 'Community') }
  scope :groups, -> { where(eventable_type: 'Group') }
  scope :past, -> { where('DATE(event_time) < ?', DateTime.now.strftime('%Y-%m-%d')) }
  scope :upcoming, -> { where('DATE(event_time) >= ?', DateTime.now.strftime('%Y-%m-%d')) }
  scope :status_approved, ->() { where('events.status = ?', Event.statuses[:approved]) }

  # Associations
  has_many :pictures, as: :imageable
  has_many :videos, as: :videoable

  has_many :event_rsvp_statuses, dependent: :destroy
  has_many :calendar_events, as: :calendarable, dependent: :destroy
  has_many :event_tags, dependent: :destroy
  has_many :webinar_speakers, as: :speakable, dependent: :destroy
  has_many :saved_events, dependent: :destroy

  scope :future, -> { where('DATE(event_time) >= ?', DateTime.now.strftime('%Y-%m-%d')) }
  scope :company_events, lambda { |user_id|
                           where(created_by_user_id: user_id).joins("left join companies on events.eventable_id = companies.id and events.eventable_type = 'Company'")
                         }
  scope :filter_by_name, ->(name) { where('name ILIKE ?', "%#{name}%") }
  scope :filter_by_name_order, ->(name_order) { order("name #{name_order}") }
  scope :filter_by_created_at_order, ->(created_at_order) { order("created_at #{created_at_order}") }

  belongs_to :eventable, polymorphic: true
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_user_id'

  has_one_attached :image

  def self.search(params, event_parent)
    events = event_parent.present? ? event_parent.events : Event.all
    events = events.filter_by_name(params[:search]) if params[:search].present?
    events = events.filter_by_name_order(params[:sort_by_name]) if params[:sort_by_name].present?
    events = events.filter_by_created_at_order(params[:sort_by_created_at]) if params[:sort_by_created_at].present?
    events
  end

  def event_date
    if self.event_time.present?
      DateTime.parse(self.event_time.to_s)
    end
  end

  def attendees
    event_rsvp_statuses.status_attending.all
  end
end
