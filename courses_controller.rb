module Api
  module V1
    class CoursesController < ApiController
      before_action :authenticate_user!, except: %i[index]
      before_action :set_course, only: %i[show update destroy mark_save]

      def index
        @courses = Course.includes(activities: [questions: :options]).with_attached_registration_form
        @courses = @courses.by_visibility_date(params[:start_date]) if params[:start_date].present?
        @courses = @courses.by_no_of_activities(params[:no_of_activities]) if params[:no_of_activities].present?
        @courses = @courses.order(created_at: :asc)
        render_success(I18n.t('courses.retrieve'), courses_data, :ok)
      end

      def create
        @course = Course.new(course_params)
        return render_success(I18n.t('courses.created'),
                              @course.as_json(methods: :image_url, include: {
                                activities: { methods: :file_url, include: {
                                  questions: {
                                    include: :options
                                  }
                                } },
                                course_schedules: {}
                              }), :created) if @course.save!

        render_error(@course.errors.messages.values.flatten.join(', '), :unprocessable_entity)
      end

      def show
        filtered_activities = @course.completed_activities.where(user_id: current_user.id).order(created_at: :asc)
        course_schedules = @course.user_course_schedules.where(user_id: current_user.id).order(created_at: :asc)
        course_registrations = @course.course_registrations.where(user_id: current_user.id).order(created_at: :asc)

        render_success(I18n.t('courses.show'),
                       @course.as_json(
                         methods: [:image_url, :register_form_url, :locked_for_user, :is_user_registered, :current_stage],
                         include: {
                           activities: { methods: :file_url, include: {
                             questions: {
                               include: {
                                 options: {}
                               }
                             }
                           } },
                           course_schedules: {}
                         }
                       ).merge!(completed_activities: filtered_activities.as_json(methods: :file_url),
                                user_course_schedules: course_schedules.as_json(include: :course_schedule),
                                course_registrations: course_registrations.as_json(methods: :form_url)),
                       :ok)
      end

      def update
        return render_success(I18n.t('courses.updated'),
                              @course.as_json(methods: :image_url, include: {
                                activities: { methods: :file_url, include: {
                                  questions: {
                                    include: :options
                                  }
                                } }
                              }), :ok) if @course.update(course_params)

        render_error(@course.errors.messages.values.flatten.join(', '), :unprocessable_entity)
      end

      def destroy
        return render_success(I18n.t('courses.deleted'), nil, :ok) if @course.destroy

        render_error(I18n.t('courses.delete_fail'), :unprocessable_entity)
      end

      def registered
        @courses = current_user.courses.includes({ activities: { questions: :options } }, :completed_activities)
        render_success(I18n.t('courses.retrieve'),
                       @courses.as_json(methods: [:image_url, :locked_for_user, :registered_users_count, :is_user_registered],
                                        include: {
                                          activities: { methods: :file_url },
                                          completed_activities: {
                                            methods: :file_url,
                                            conditions: { user_id: current_user.id }
                                          }
                                        }), :ok)
      end

      def saved
        @saved_courses = current_user.saved_courses.includes(course: { activities: { questions: :options }, completed_activities: {} })
        render_saved_or_completed_courses(@saved_courses)
      end

      def completed
        @completed_courses = Course.user_completed_courses.includes(activities: { questions: :options }, completed_activities: {})
        render_success(
          I18n.t('courses.retrieve'),
          @completed_courses.as_json(
            methods: [:image_url, :locked_for_user, :registered_users_count, :is_user_registered],
            include: {
              activities: { methods: :file_url, include: {
                questions: {
                  include: {
                    options: {}
                  }
                }
              } },
              completed_activities: {
                methods: :file_url,
                conditions: { user_id: current_user.id }
              }
            }
          ), :ok)
      end

      def submitted_activities
        @submitted_activities = CompletedActivity
                                  .includes(
                                    { user: { user_course_schedules: :course_schedule } },
                                    :course
                                  )
                                  .order(created_at: :desc)
        render_success(
          I18n.t('courses.list_submitted_activities'),
          @submitted_activities.as_json(
            methods: [:file_url],
            include: {
              user: {
                include: { user_course_schedules: { include: :course_schedule } }
              },
              course: {}
            }
          ),
          :ok
        )
      end

      def mark_save
        saved_course = current_user.saved_courses.find_or_create_by(course: @course)

        return render_error(I18n.t('courses.save_fail'), :unprocessable_entity) unless saved_course.persisted?

        render_success(I18n.t('courses.mark_save'),
                       @course.as_json(methods: :image_url, include: { activities: { methods: :file_url } }), :ok)
      end

      def remove_course_schedule
        @schedule = CourseSchedule.find_by(id: params[:id].to_i)
        return render_error('not found', :not_found) unless @schedule

        course = @schedule.course
        return render_success('deleted successfully', course.course_schedules, :ok) if @schedule.destroy

        render_error('could not delete', :unprocessable_entity)
      end

      def remove_activity
        @activity = Activity.find_by(id: params[:activity_id].to_i)

        return render_error('not found', :not_found) unless @activity

        course = @activity.course
        return render_success('deleted successfully', course.activities, :ok) if @activity.destroy

        render_error('could not delete', :unprocessable_entity)
      end

      private

      def course_params
        params.require(:course).permit(:course_name, :no_of_activities, :image, :objectives, :details, :registration_form,
                                       :questionnaire_link, :details, :objectives, :is_published, :from_time, :to_time,
                                       activities_attributes: [:id, :name, :description, :kind, :file, :_destroy,
                                                               questions_attributes: [:id, :statement, :kind, :_destroy,
                                                                                      options_attributes: [:id, :title, :kind, :is_answer, :_destroy]]],
                                       course_schedules_attributes: [:id, :city, :schedule_date, :_destroy])
      end

      def set_course
        @course = Course.find_by(id: params[:id].to_i)

        render_error(I18n.t('courses.not_found'), :not_found) unless @course
      end

      def courses_data
        return @courses.as_json(methods: [:image_url, :register_form_url], include: {
          activities: { methods: :file_url, include: {
            questions: {
              include: {
                options: {}
              }
            }
          } }
        }) if current_user.nil?

        @courses.as_json(
          methods: [:image_url, :register_form_url, :locked_for_user, :is_user_registered],
          include: {
            activities: { methods: :file_url, include: {
              questions: {
                include: {
                  options: {}
                }
              }
            } },
            completed_activities: {
              methods: :file_url,
              conditions: { user_id: current_user.id }
            },
            course_schedules: {},
            registration_form: {
              include: :blob
            }
          }
        )
      end

      def render_saved_or_completed_courses(courses)
        render_success(
          I18n.t('courses.retrieve'),
          courses.as_json(
            include: {
              course: {
                methods: [:image_url, :locked_for_user, :registered_users_count, :is_user_registered],
                include: {
                  activities: { methods: :file_url, include: {
                    questions: {
                      include: {
                        options: {}
                      }
                    }
                  } },
                  completed_activities: {
                    methods: :file_url,
                    conditions: { user_id: current_user.id }
                  }
                }
              }
            }
          ),
          :ok
        )
      end
    end
  end
end
