# frozen_string_literal: true

# communities
class CommunitiesController < OrganizationsController
  include SpreadSheet
  include DocumentsConcern
  include Newsfeed

  before_action :authenticate_user!
  before_action :set_community, except: %i[index new create my_communities community_notification saved_community_notification]
  before_action :check_community_admin,
                only: %i[edit update destroy show_user_community_requests approve_user_community_request]
  after_action :page_view_track, only: %i[show]
  before_action :check_community_permissions, only: %i[home new_webinar edit_webinar webinar_management new_event edit_event event_management]
  before_action :check_document_repository_permissions, only: %i[files]
  protect_from_forgery except: [:filter_users]
  before_action :calendar, only: %i[filtered_events events_time show]
  before_action :set_limit, only: %i[show paginate]
  include EventDate
  include CommunityConcern

  def index
    pages(Community.approved.search(params), 9)
  end

  def show
    @user_communities = @community.user_communities.where(status: UserCommunity.statuses[:approved])
    set_community_feed
    @post = Post.new
    @community_events = @community.events
    @webinars = @community.webinars
    @upcoming_webinars = @community.webinars.upcoming.all
    @past_webinars = @community.webinars.past.all
    @upcoming_events = @community.events.upcoming.all
    @past_events = @community.events.past.all
    @community_admins = @community.community_admins
    @community_managers = @community.community_managers
    @first_two_events = @community.upcomming_events.first(2)
    @friends_in_community = @community.friends_in_community(current_user.id)
    @friends_in_community_exist = @friends_in_community.present?
    @news = get_news_feed_data
    @combined_news = []
    @community.categories.each do |category|
      category_name = category.name.gsub(/\W+/, "").downcase
      category_news = @news.select { |news| news['category'].gsub(/\W+/, "").downcase == category_name }
      @combined_news += category_news
    end
    if @friends_in_community.blank?
      @friends_in_community = @community.user_communities.where(status: UserCommunity.statuses[:approved]).sample(4)
      @remaining_friends_in_community = @user_communities.count - @friends_in_community.count
    end
    if (token = session[:token].presence || params[:token].presence)
      @invite = Invite.find_by(invitation_token: token)
      redirect_to accept_invitation_community_path(@invite.invitable.slug, user_id: @invite.invited_by) if @invite&.invitee.to_i == current_user.id
    end
  end

  def paginate
    @offset = params[:offset].to_i
    set_community_feed
    @html = ''
    @feed.each do |feed|
      @html += render_to_string partial: "feed/feed_item", locals: { feed: feed, postable_type: 'Community' }
    end

    render json: {
      status: @feed.present? && @feed.size > 0 ? true : false,
      offset: @offset + @limit,
      html: @html
    }
  end

  def new
    @community = Community.new
  end

  def edit
    @user_communities = @community.user_communities.where.not('user_id = ? AND status = ?', current_user.id, UserCommunity.statuses[:approved]).where.not(
      'status = ?', UserCommunity.statuses[:requested]
    )
  end

  def create
    @community = Community.new(community_params)
    respond_to do |format|
      if @community.save
        @community.add_admin(current_user.id)
        format.html { redirect_to communities_path, notice: 'Community was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  def update
    respond_to do |format|
      if @community.update(community_params)
        format.html { redirect_to files_community_path(@community), notice: 'Document was successfully uploaded.'} if params[:documents].present?
        format.html { redirect_to communities_path, notice: 'Community was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  def importer_members
    file = params[:file]
    extension = File.extname(file.original_filename).downcase
    if ['.csv', '.xls', '.xlsx'].include?(extension)
      spreadsheet = open_spreadsheet(file)
      sheet = spreadsheet.sheet(0)
      header = header(sheet)
      create_members(sheet, header)
      flash[:notice] = 'Communities members imported succesfully.'
      render json: { status: true, message: 'Communities members imported succesfully.' }
    else
      render json: { status: false, message: "#{extension} is not an acceptable file type. Please use .xls, .xlsx, or .csv." }
    end
  end

  def import_members; end

  def destroy
    @community.destroy
    respond_to do |format|
      format.html { redirect_to communities_path, notice: 'Community was successfully destroyed.' }
    end
  end

  def delete_user_community
    @community.user_communities.where(user_id: params[:user_id]).destroy_all
    respond_to do |format|
      format.html { redirect_to communities_path, notice: 'Left Community successfully.' }
    end
  end

  def webinar_management
    @past_webinars = @community.webinars.past.all
    @upcoming_webinars = @community.webinars.upcoming.all

  end

  def request_user_community
    @community.add_user_community(current_user.id, params[:user_id], 'requested')
    send_email_to_community_admins(@community, current_user)
    respond_to do |format|
      format.html { redirect_to communities_path, notice: 'Request is sent to join Community successfully.' }
    end
  end

  def join_community
    community_user = @community.user_communities.find_by(user_id: current_user.id)
    session.delete(:token) if session[:token].present?

    if community_user.present? && community_user.status != 'approved'
      community_user.update(status: 'approved')
      notice = 'Joined Community successfully'
    elsif community_user.nil?
      @community.add_user_community(current_user.id, params[:user_id], 'approved')
      notice = 'Joined Community successfully'
    else
      notice = community_user.present? ? 'Already Joined' : 'Already Rejected'
    end
    # send_email_to_community_admins(@community, current_user)
    respond_to do |format|
      format.html { redirect_to community_path(@community), notice: notice }
    end
  end

  def approve_user_community_request
    user_community = @community.user_communities.where(id: params[:user_community_id]).first
    user_community.status = UserCommunity.statuses[:approved]
    user_community.save
    respond_to do |format|
      format.html do
        redirect_to show_user_community_requests_community_path(@community.id), notice: 'Aprroved Request successfully.'
      end
    end
  end

  def show_user_community_requests
    @user_community_requests = @community.pending_requests
  end

  def reject_user_community_invitation
    @community.user_communities.where(user_id: params[:user_id]).destroy_all
    respond_to do |format|
      format.html { redirect_to requests_path, notice: 'Invitation rejected successfully .' }
    end
  end

  def my_communities
    @communities = current_user.communities
  end

  def community_members
    @community_members = @community.user_communities.where('role != ? AND status = ?', UserCommunity.roles[:admin],
                                                           UserCommunity.statuses[:approved])
  end

  def members
    if @community.admin_user?(current_user.id) || current_user.admin? || @community.user_community?(@current_user.id)
      @users = User.joins(:user_communities).where('user_communities.community_id = ?', @community.id).distinct
      @users = User.where.not(id: @users.ids)
    else
      return redirect_to communities_path unless @community.admin_user?(current_user.id) || current_user.admin?
    end

    @type = params[:type] || 'all'
    @role = params[:role] if params[:role].present?
    @status = params[:status] if params[:status].present?
    members = filter_members_by_type(@type)

    if @role.present? && @role != 'All'
      members = members.select { |uc| uc.role == @role }
    end

    if @status.present? && @status != 'All'
      members = members.select { |uc| uc.user.user_type&.gsub(/\W+/, "")&.tr("_","") == @status.downcase.gsub(/\W+/, "") }
    elsif @status.present? && @status == 'All'
      members
    end

    community_admin_count(members)
    pages(members, 10, nil, 'members')
    @type = params[:type] || 'all'
  end

  def filters
    @type = params[:type] || 'all'
    @role = params[:role] if params[:role].present?
    @status = params[:status] if params[:status].present?
    members = filter_members_by_type(@type)

    if @role.present? && @role != 'All'
      members = members.select { |uc| uc.role == @role }
    elsif @role.present? && @role == 'All'
      members
    end

    if @status.present? && @status != 'All'
      members = members.select { |uc| uc.user.user_type&.gsub(/\W+/, "")&.tr("_","") == @status.downcase.gsub(/\W+/, "") }
    elsif @status.present? && @status == 'All'
      members
    end

    community_admin_count(members)

    pages(members, 10, nil, 'members')
    @type = params[:type] || 'all'
    if @type == "all"
    render partial: 'communities/approved_members', locals: { '@members': @members, '@community': @community }
    elsif @type == "pending"
    render partial: 'communities/pending_members', locals: { '@members': @members, '@community': @community }
    elsif @type == "pending_invitations"
      render partial: 'communities/requested_members', locals: { '@members': @members, '@community': @community }
    elsif @type == "removed"
      render partial: 'communities/deleted_members', locals: { '@members': @members, '@community': @community }
    end

  end

  def event_management
    @past_events     = @community.events.past.includes(:event_rsvp_statuses).all
    @upcoming_events = @community.events.upcoming.includes(:event_rsvp_statuses).all
  end

  def new_event
    @event = @community.events.build
  end

  def edit_event
    @event = @community.events.where(slug: params[:slug]).first
  end

  def update_event
    data = event_params
    data[:event_time] = format_event_date
    @event = @community.events
    if @event.where(slug: params[:slug]).first.update(data)
      redirect_to communities_path, notice: 'Event has been updated successfully.'
    else
      render :edit_event
    end
  end

  def create_event
    data = event_params
    data[:event_time] = format_event_date
    data[:slug] = "#{@community.name} #{data[:name]}".parameterize
    @event = @community.events.new(data)
    if @event.save
      redirect_to communities_path, notice: 'Event has been created successfully.'
    else
      render :new_event
    end
  end

  def new_webinar
    @webinar = @community.webinars.build
  end

  def edit_webinar
    @webinar = @community.webinars.where(slug: params[:slug]).first
    if @webinar&.ended? || @webinar&.webinar_time.to_i < DateTime.now.to_i
      redirect_to webinar_management_community_path(@community), notice: "Editing is not allowed for this webinar."
    end
  end

  def update_webinar
    data = webinar_params
    data[:webinar_time] = format_webinar_date
    @webinar = @community.webinars.where(slug: params[:slug]).first
    if @webinar.update(data)
      save_webinar_pictures
      redirect_to communities_path, notice: 'webinar has been updated successfully.'
    else
      render :edit_webinar
    end
  end

  def create_webinar
    data = webinar_params
    data[:webinar_time] = format_webinar_date
    data[:slug] = "#{@community.name} #{data[:name]}".parameterize
    @webinar = @community.webinars.new(data)
    if @webinar.save
      save_webinar_pictures
      response = LiveStormService.new.create_webinar(@webinar)

      set_live_strom_webinar(response)
      redirect_to webinar_management_community_path(@community), notice: 'webinar has been updated successfully.'
    else
      render :new_webinar
    end
  end

  def filter_users
    invite_member(params[:user_id],nil,nil) if params[:user_id]
    @users = User.joins(:user_communities).where('user_communities.community_id = ?', @community.id).distinct
    @users = User.where.not(id: @users.ids)
    if params[:name]
      first_name = params[:name].split.first
      last_name = params[:name].split.last
      @users = @users.filter_by_full_name(first_name, last_name)
    else
      @users = @users.filter_by_full_name('', '')
    end
  end

  def invite_member(user_id,user_role,invitation)
    @user_community = UserCommunity.new(community_id: @community.id, user_id: user_id,role: user_role, status: 'invited')
    if @user_community.save!
      sent_email = CommunityMailer.invite_community_member(@user_community.id,current_user,invitation) if @user_community&.user.notification_preference&.community_invitations_email_notifications
      EmailSent.create(email_message_id: sent_email&.message_id, email_delivered_to_user_id: user_id, email_classification: :community_member_invitation, email_source: check_user_type, email_subject: sent_email&.subject, sender_email: sent_email&.from&.join) if sent_email&.present?
      flash[:notice] = "Your invitation has been sent to '#{@user_community.user.email}'."
      respond_to do |format|
        format.js { render js: "window.location='#{members_community_path(@community.id)}'"}
        format.html { redirect_to members_community_path(@community.id)}
      end
    end
  end

  def resend_invite
    @user_community = UserCommunity.find_by(community_id: @community.id, user_id: params[:user_id], status: 'invited')
    if @user_community.present?
      CommunityMailer.invite_community_member(@user_community.id,current_user,nil)
      respond_to do |format|
        format.html do
          redirect_to members_community_path(@community.id), notice: "Your invitation has been sent to  '#{@user_community.user.email}'. again"
        end
      end
    end
  end

  def cancel_invitation
    @user_community = UserCommunity.find_by(community_id: @community.id, user_id: params[:user_id], status: 'invited')
    @user_community.destroy
    respond_to do |format|
      format.html do
        redirect_to members_community_path(@community.id), notice: 'Your invitation request has been cancelled'
      end
    end
  end

  def requests
    @user_community_invitations = @community.user_communities.invited
  end

  def approve_user_community_invitation
    user_community = @community.user_communities.find_by(id: params[:user_community_id])
    user_community.status = UserCommunity.statuses[:approved]
    user_community.save
    respond_to do |format|
      format.html do
        redirect_to requests_path, notice: 'Aprroved Request successfully.'
      end
    end
  end

  def invite_users_by_email
    @user = User.find_by(email: params[:email])
    user_role = params[:role].presence
    if @user
      @user_community = UserCommunity.where(community_id: @community.id, user_id: @user.id)
      if @user_community.blank?
        @invitation = Invite.create(invitable: @community, invited_by:current_user.id,invitee: @user.id)
        notification = Notification.create(invite_id: @invitation.id, user_id: @user.id)
        UserNotification.create(user_id: @user.id, notification_id: notification.id, notification_muted: !@user.notification_preference&.community_invitations_in_app_notifications)
        invite_member(@user.id,user_role,@invitation)
      elsif @user_community.first.status != "approved"
        flash[:alert] = "The user's status for this community is not approved or accepted."
          respond_to do |format|
            format.js { render js: "window.location='#{members_community_path(@community.id)}'"}
            format.html { redirect_to members_community_path(@community.id)}
          end
      else
        flash[:notice] = 'This user is already  a member of this community'
          respond_to do |format|
            format.js { render js: "window.location='#{members_community_path(@community.id)}'"}
            format.html { redirect_to members_community_path(@community.id)}
          end
      end
    else
      @user = User.new(email: params[:email])
      @user.save(validate: false)
      if @user
        @invitation = Invite.create(invitable: @community, invited_by:current_user.id,invitee: @user.id)
        UserCommunity.create(community_id: @community.id, role: user_role, status: 'invited', user_id: @user.id)
        sent_email = CommunityMailer.invite_community_member_by_email(@community, params[:email], @invitation, signup_url)
        EmailSent.create(email_message_id: sent_email&.message_id, email_delivered_to_user_id: @user&.id, email_classification: :community_member_invitation, email_source: check_user_type, email_subject: sent_email&.subject, sender_email: sent_email&.from&.join) if sent_email&.present?
        Notification.create(invite_id: @invitation.id, user_id: @user.id)
        flash[:notice] ="Your invitation has been sent to '#{params[:email]}'."
        respond_to do |format|
          format.js { render js: "window.location='#{members_community_path(@community.id)}'"}
          format.html { redirect_to members_community_path(@community.id)}
        end
      else
        flash[:notice] ="Failed to send the invitation. Please try again later."
        render js: "window.location='#{members_community_path(@community.id)}'"
      end
    end
  end

  def remove_member
    user_community = @community.user_communities.find_by(user_id: params[:user_id])
    user_community.destroy
    redirect_to @community, notice: "User #{user_community.user.email} was removed from the community."
  end

  def reinstate_member
    user_community = UserCommunity.only_deleted.find_by(user_id: params[:user_id])
    if user_community.nil?
      redirect_to @community, notice: "User is not a member of the communtiy."
    elsif @community.user_communities.exists?(user_id: user_community.user_id)
      redirect_to @community, notice: "User is already a member of the communtiy."
    else
      user_community.restore
      redirect_to @community, notice: "User #{user_community.user.email} was added to the Community."
    end
  end

  def set_admin
    user_community = @community.user_communities.find_by(user_id: params[:user_id])
    user_community.update(role: "admin")
    redirect_back(fallback_location: root_path, notice: "User #{user_community.user.email} was set as admin.")
  end

  def set_general_user
    user_community = @community.user_communities.find_by(user_id: params[:user_id])
    user_community.update(role: "general")
    redirect_back(fallback_location: root_path, notice: "User #{user_community.user.email} was set as general user.")
  end

  def set_manager_user
    user_community = @community.user_communities.find_by(user_id: params[:user_id])
    user_community.update(role: "manager")
    redirect_back(fallback_location: root_path, notice: "User #{user_community.user.email} was set as manager user.")
  end

  def community_admin_count(members)
    @admins_count = 0
    members.each do |user|
      if user.role == "admin"
        @admins_count += 1
      end
    end
  end

  def calendar
    community_events = []
    community_webinars = []
    @community.events.where(status: "approved").each do |event|
      community_events << event
    end

    @community.webinars.where(status: "approved").each do |webinar|
      community_webinars << webinar
    end

    @events = (community_events + community_webinars).uniq
    events_time
  end

  def filtered_events
    checked_events = params[:checked_events]
    @filtered_events = []

    @events.each do |event|
      unless !checked_events&.include?(event.class.name.downcase)
        @filtered_events << event
      end
    end

    render json: @filtered_events
  end

  def community_notification
  end

  def saved_community_notification;end

  def files
    filter_documents(@community.posts)
  end

  def chat_management;end

  def search_member
    community_users  = @community.users
    @community_users = if params[:search].present?
                     community_users.search_by_full_name(params[:search])
                   else
                     community_users
                   end
  end

  def reject_invitation 
    @community.user_communities.where(user_id: params[:user_id]).destroy_all
    session.delete(:token) if session[:token].present?

    respond_to do |format|
      format.html { redirect_to user_path(User.find(params[:user_id]).slug), notice: 'Decline Community Join Request successfully.' }
    end
  end

  private

  def set_community_feed
    sort_direction = params[:sort_by_created_at] || 'desc'
    offset = @offset || 0
    @feed = @community.activities&.order("created_at #{sort_direction}, id").limit(@limit).offset(offset)
  end

  def set_limit
    @limit = 10
  end

  def events_time
    @events_time = []
    @events.each do |event|
      if event.class.name == "Event"
        @events_time << event.event_time&.strftime("%Y-%m-%d")
      elsif event.class.name == "Webinar"
        @events_time << event.webinar_time&.strftime("%Y-%m-%d")
      end
    end
    @events_time
  end


  def filter_members_by_type(type)
    case type
    when 'all'
      UserCommunity.includes(:community, :user).where(community_id: @community.id, status: 'approved')
    when 'pending'
      UserCommunity.includes(:community, :user).where(community_id: @community.id, status: 'requested')
    when 'pending_invitations'
      UserCommunity.includes(:community, :user).where(community_id: @community.id, status: 'invited')
    when 'removed'
      UserCommunity.only_deleted.includes(:community, :user).where(community_id: @community.id)
    else
      UserCommunity.none
    end
  end

  def report_progress(imported_records, total_records, first_name, last_name)
    progress = (imported_records.to_f / total_records.to_f) * 100
    ActionCable.server.broadcast('data_import_progress', { progress: progress, first_name: first_name, last_name: last_name })
  end

  def create_members(sheet, header)
    ((sheet.first_row + 1)..sheet.last_row).each do |i|
      model_hash = [header, sheet.row(i)].transpose.to_h
      next unless model_hash['email'].present?

      p "=========== i: #{i} ==========="
      user = User.where(email: model_hash['email'])
      if user.exists?
        user = user.first
        user_id = user.id
      else
        user = User.new
        user.email = model_hash['email']
        user.first_name = model_hash['first_name']
        user.last_name = model_hash['last_name']
        user.save!(validate: false)
        user_id = user.id
      end
      UserCommunity.where(community_id: @community.id, user_id: user_id).destroy_all
      if @community.user_communities.find_by(user_id: user_id).nil?
        @community.user_communities.create(user_id: user_id, status: 'requested')
      end
      @invitation = Invite.create(invitable: @community, invited_by: @community.id)
      CommunityMailer.send_request(@community, user.email, @invitation, signup_url).deliver_now
      @community.user_communities.find_by(user_id: user_id)&.update(status: 'invited')

      report_progress(i, sheet.last_row, user.first_name, user.last_name)
    end
  end

  def save_webinar_pictures
    if params[:webinar][:pictures_attributes].present?
      params[:webinar][:pictures_attributes]['0']['image'].each do |image|
        @webinar.pictures.create(image: image, user_id: current_user.id) if image.present?
      end
    end
  end

  def check_community_admin
    redirect_to communities_path unless current_user.admin? || @community.admin_user?(current_user.id)
  end

  def check_community_permissions
    redirect_to communities_path, notice: 'Only admins or managers can access this page.' unless current_user.admin? || @community.manager_user?(current_user.id) || @community.admin_user?(current_user.id)
  end

  def check_document_repository_permissions
    redirect_to communities_path, notice: "Only admins or approved community members can access this page." unless @community.approved_community_manager?(current_user)
  end

  def set_community
    @community = Community.friendly.find(params[:id] || params[:community_name] || params[:slug]) || Community.first
  end

  def community_params
    params.require(:community).permit(:name, :active, :user_submitted, :description,
                                      :category, :community_type,
                                      user_communities_attributes: %i[id user_id status _destroy],
                                      documents_attributes: %i[id user_id doc _destroy],
                                      picture_attributes: %i[id image _destroy])
  end

  def event_params
    params.require(:event).permit(:name, :description, :event_time, :time_zone,
                                  :event_type, :location, :phone_number, :eventable_id)
          .merge(created_by_user_id: current_user.id)
  end

  def webinar_params
    params.require(:webinar).permit(:name, :description, :webinar_time, :image, :time_zone,
                                    :location, :phone_number, :webinarable_id)
          .merge(created_by_user_id: current_user.id)
  end

  def set_live_strom_webinar(response)
    return if response['data'].nil?

    owner_id = response['data']['attributes']['owner']['id'] # livestrom id for user who created webinar
    session_id = response['data']['relationships']['sessions']['data'].first['id'] # session id for that webinar
    webinar_livestorm_id = response['data']['id']

    @webinar.update(live_storm_id: webinar_livestorm_id, livestorm_session_id: session_id)

    User.find_by(id: @webinar.created_by.id)&.update(livestorm_id: owner_id)
  end

  def check_user_type
    return 'Admin' if current_user.admin?

    manager_user = ManagerUser.find_by(manageable: @community, user: current_user)
    "Community #{manager_user.status.humanize}" if manager_user.present?
  end
end
