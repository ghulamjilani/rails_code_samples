class Course < ApplicationRecord
  include S3UrlFinder

  # has_many :attachments, as: :attachable, dependent: :destroy
  has_many :course_registrations, dependent: :destroy
  has_many :users, through: :course_registrations
  has_many :saved_courses, dependent: :destroy
  has_many :completed_activities, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :user_course_schedules, dependent: :destroy
  has_many :scheduled_users, through: :user_course_schedules, source: :user
  has_many :course_schedules, dependent: :destroy
  has_many :attendances, dependent: :destroy

  has_one_attached :image
  has_one_attached :registration_form

  validates :course_name, presence: true

  # accepts_nested_attributes_for :attachments, allow_destroy: true
  accepts_nested_attributes_for :activities, allow_destroy: true
  accepts_nested_attributes_for :course_schedules, allow_destroy: true

  scope :by_visibility_date, ->(start_date) { where(visibility_date: start_date) }
  scope :by_no_of_activities, ->(no_of_activities) { where(no_of_activities: no_of_activities) }
  scope :published, -> { where(is_published: true) }

  after_create :notify_all_employees

  def image_url
    fetch_attachment_url_from_s3(image) if image.attached?
  end

  def register_form_url
    fetch_attachment_url_from_s3(registration_form) if registration_form.attached?
  end

  def locked_for_user
    if previous_course_completed? || enough_progress_completed?
      false
    else
      true
    end
  end

  def registered_users_count
    users.size
  end

  def is_user_registered
    course_registrations.exists?(user_id: Current.user&.id, status: 'approved')
  end

  def current_stage
    return 'scheduling' unless Current.user
    
    approved_schedule = user_course_schedules.find_by(user_id: Current.user.id)
    return 'scheduling' unless approved_schedule
    
    return 'register' unless is_user_registered

    user_completed_activities = completed_activities.where(user_id: Current.user&.id)
    return 'questionnaire' if no_of_activities == user_completed_activities&.size
    
    'activities'
  end

  private

  def previous_course_completed?
    previous_course = Course.where("id < ?", id)&.last
    return true if previous_course.nil?

    Course.user_completed_courses.include?(previous_course)
  end

  def self.user_completed_courses
    completed_courses = Course.joins(:completed_activities)
                              .where(completed_activities: { user_id: Current.user.id })
                              .group('courses.id')
                              .having('COUNT(completed_activities.id) = courses.no_of_activities')

    completed_courses
  end

  def enough_progress_completed?
    completed_percentage = (Current.user&.completed_activities.where(course_id: self.id).count&.to_f || 0 / no_of_activities) * 100
    completed_percentage >= 80
  end

  def notify_all_employees
    notification = Notification.create!(sender: Current.user, title: 'تمت إضافة دورة جديدة', description: 'تمت إضافة دورة جديدة من قبل المشرف')

    employees_ids = User.employees.activated.pluck(:id)
    employees_notifications = employees_ids.map { |employee_id| { user_id: employee_id, notification_id: notification&.id } }

    UserNotification.upsert_all(employees_notifications, unique_by: [:user_id, :notification_id])
  end

  def self.all_courses_with_registration_and_completion
    courses = Course.left_outer_joins(:course_registrations, user_course_schedules: :course_schedule)
                    .where('course_registrations.status = ? OR course_registrations.id IS NULL', 1)
                    .where('user_course_schedules.status = ? OR user_course_schedules.id IS NULL', 1)
                    .distinct

    courses_completed = courses.merge(Course.user_completed_courses)

    courses_array = courses.to_a
    courses_completed_array = courses_completed.to_a

    in_progress_courses = courses_array - courses_completed_array

    [courses_completed_array, in_progress_courses]

  end
end
