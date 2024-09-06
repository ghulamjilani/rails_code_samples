module Api
  module V1
    class AttendanceController < ApiController
      def index
        @attendance_data = User.employees.activated.with_specific_attributes.includes(attendances: {course: :course_registrations})
        @attendance_data = @attendance_data.by_courses(params[:course_ids]) if params[:course_ids].present?
        @attendance_data = @attendance_data.by_attendance_status(params[:status]) if params[:status].present?
        @attendance_data = @attendance_data.by_job_number(params[:employee_number]) if params[:employee_number].present?
        @attendance_data = @attendance_data.distinct.order(created_at: :asc).page(params[:page]).per(params[:per_page])

        paginated_response(I18n.t('attendance.list'), @attendance_data.as_json(include: { attendances: { include: :course }, course_registrations: {} }),
                           @attendance_data, 'attendance_data', :ok)
      end

      def record
        employee = User.find_by(phone_number: params[:phone_number], employee_number: params[:employee_number])

        return render_error(I18n.t('devise.sessions.not_found'), :not_found) unless employee
        return render_error(I18n.t('devise.sessions.role_not_exist'), :not_found) unless employee.has_role?(I18n.t('roles.employee'))
        return render_error(I18n.t('devise.sessions.not_activated'), :unprocessable_entity) unless employee.activated

        course = Course.find_by(id: params[:course_id])
        return render_error(I18n.t('courses.not_found'), :not_found) unless course

        return render_error(I18n.t('attendance.not_registered'), :unprocessable_entity) unless CourseRegistration.exists?(user: employee, course: course, status: 'approved')
        return render_error(I18n.t('attendance.already_marked'), :unprocessable_entity) if Attendance.exists?(employee: employee, course: course, attendance_date: Date.today)

        new_attendance = Attendance.create(employee: employee, course: course, attendance_date: Date.today, status: 0)
        render_success(I18n.t('attendance.record_success'), new_attendance.as_json(include: [:employee, :course]), :created)
      end

      def update
        @attendance = Attendance.find_by(id: params[:id])
        return render_error(I18n.t('attendance.not_found'), :not_found) unless @attendance

        return render_success(I18n.t('attendance.update_success'), @attendance.as_json(include: :course), :ok) if @attendance.update(status: params[:status])

        render_error(I18n.t('attendance.update_fail'), :unprocessable_entity)
      end

      def mark
        employee_id = params[:employee_id]
        course_id = params[:course_id]
        status = params[:status]
      
        return render_error(I18n.t('attendance.missing_params'), :bad_request) if employee_id.nil? || course_id.nil? || status.nil?
      
        new_attendance = Attendance.new(
          employee_id: employee_id, 
          course_id: course_id,
          attendance_date: Date.today, 
          status: status
        )
      
        return render_error(I18n.t('attendance.update_fail'), :unprocessable_entity) unless new_attendance.save
      
        render_success(I18n.t('attendance.record_success'), new_attendance.as_json(include: :course), :created)
      end
    end
  end
end
