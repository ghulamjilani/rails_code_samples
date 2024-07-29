# frozen_string_literal: true

class Student < ApplicationRecord
  include S3UrlFinder
  DATE_RANGE = Date.current.beginning_of_month - 3.months..Date.current.end_of_month

  enum :status, %i[waiting approved rejected left]
  enum :gender, %i[male female]

  belongs_to :madrassa,  optional: true
  belongs_to :standard, optional: true
  belongs_to :region,  optional: true

  has_many :scores, dependent: :destroy
  has_many :guardians, dependent: :destroy
  has_many :local_contacts, dependent: :destroy
  has_one :gp, dependent: :destroy
  has_one :supplementary_detail, dependent: :destroy
  has_one :consent, dependent: :destroy
  has_many :student_subjects, dependent: :destroy
  has_many :subjects, through: :student_subjects
  has_many :daily_attendances, dependent: :destroy
  has_many :reports, dependent: :destroy

  has_one_attached :image

  scope :_list, ->(status) { where(status:) }
  scope :for_last_3_months, lambda {
                              where(approved_at: DATE_RANGE)
                            }
  scope :by_teacher, ->(teacher) {
    class_ids = teacher.standards&.ids
    joins(standard: :teachers).where(standard_id: class_ids)&.distinct
  }

  scope :search_by_name, ->(query) {
    where("lower(first_name) LIKE ? OR lower(middle_name) LIKE ? OR lower(last_name) LIKE ?"\
            " OR concat_ws(' ' , lower(first_name), lower(middle_name), lower(last_name)) LIKE ?"\
            " OR concat_ws(' ' , lower(first_name), lower(last_name)) LIKE ?",
            "%#{query.downcase}%", "%#{query.downcase}%", "%#{query.downcase}%", "%#{query.downcase}%", "%#{query.downcase}%")
  }

  scope :by_attendance, ->(attendance_status) { joins(:daily_attendances).where(daily_attendances: { attendance_status: attendance_status, attendance_date: Date.today }) }

  validates :first_name, :last_name, :date_of_birth, :house_no, :post_code, :previous_madrasah_attended,
            :reason_for_leaving, :other_children_studying, presence: true

  after_save :add_student_subject, if: :student_approved?
  after_update :send_message_notification_of_approve_or_reject, if: -> { saved_change_to_status? }

  accepts_nested_attributes_for :guardians, :local_contacts, :gp, :supplementary_detail, :consent, allow_destroy: true
  
  def score_added_today?
    scores.for_today.exists?
  end

  def full_name
    [first_name, middle_name ,last_name].join(' ')
  end

  def student_approved?
    saved_change_to_status? && approved?
  end

  def add_student_subject
    StudentSubject.find_or_create_by!(student_id: id, subject_id: Subject.find_by(name: 'Qaidah').id)
  end

  def current_subject
    student_subjects.find_by(is_active: true)&.subject
  end

  def image_url
    fetch_attachment_url_from_s3(image) if image.attached?
  end

  def is_on_leave_today?
    return false unless daily_attendances.of_today.any?

    daily_attendances&.of_today&.last.is_leave?
  end

  def current_teacher
    standard&.teachers&.last
  end

  def send_message_notification_of_approve_or_reject
    if status == 'approved' || status== 'rejected'
      receiver_contacts = guardians.pluck(:contact_details).compact
      message = "Dear Parent!\n#{full_name}'s admission was #{status}.\nPlease do not reply to this message because this is a system generated message. If you have any queries you can please visit us or contact us on: #{madrassa.phone_no}\n\nYour here and hereafter,\n
#{madrassa.head_teacher.name}\nHead Teacher at #{madrassa.name}"
      receiver_contacts.each { |contact| Twilio::Message.call(contact, message) }
    end
  end
end
