module UserHelper
  require 'action_view'
  include ActionView::Helpers::DateHelper

  def date_in_words(date)
    date.present? ? "updated #{distance_of_time_in_words(Time.zone.now, date)}" : ""
  end

  def user_picture_url(user)
    if user.picture.present?
      Rails.application.routes.url_helpers.url_for(user.picture.image)
    else
      'users/avatar-placeholder.png'
    end
  end

  def user_picture(user, width = 32, height = 32, class_attr = '')
    if user.picture.present?
      image_tag(user.picture.image, width: width, height: height, class: class_attr)
    else
      "<span class='messages_empty_avatar_holder'><span class='messages_avatar_letters'>#{user.full_name.chr}</span></span>"
    end
  end

  def user_type_image(user)
    url = case user.user_type
          when 'undergraduate_student'
            'job-management-board/undergraduate-student.svg'
          when 'graduate_student'
            'job-management-board/graduate-student.svg'
          when 'post_graduate_fellow'
            'job-management-board/post-graduate-fellow.svg'
          when 'bio_pharma_r_&_d'
            'job-management-board/corporate-researcher.svg'
          else
            'job-management-board/academic-researcher.svg'
          end
    image_tag url, size: '18x18'
  end

  def user_type_class(user)
    url = case user.user_type
          when 'undergraduate_student'
            'undergrad'
          when 'graduate_student'
            'grad'
          when 'post_graduate_fellow'
            'postgrad'
          else
            'academic'
          end
  end

  def user_permission_url(user, current_user_privilege)
    current_user_privilege.present? || user_privacy?(user)  ? user_path(user) : user_path(user.display_id)
  end

  def last_three_research_areas(user)
    user.research_areas.last(3)
  end

  def objs_count(objs)
    objs&.count || 0
  end

  def paper_user(paper_id)
    User.joins(saved_pubmed_papers: :saved_items)&.where(saved_items: {saveable_id: paper_id, saveable_type: 'PubmedPaper'})&.last
  end

  def job_posted_time(created_date)
    days = (DateTime.now.to_date - created_date.to_date).to_i
    days == 0 ? "Today" : "#{days} days ago"
  end
  # Regex to find YouTube's and Vimeo's video ID
  YOUTUBE_REGEX = %r(^(https*://)?(www.)?(youtube.com|youtu.be)/(watch\?v=){0,1}([a-zA-Z0-9_-]{11}))
  VIMEO_REGEX =  %r{^(?:https?://)?(?:www\.)?(?:vimeo\.com/(?:channels/[\w-]+/|showcase/\d+/video/)?|player\.vimeo\.com/video/)(\d+)(?:\?.*)?$}

  # Finds YouTube's video ID from given URL or [nil] if URL is invalid
  # The video ID matches the RegEx \[a-zA-Z0-9_-]{11}\
  def find_youtube_id(url)
    matches = YOUTUBE_REGEX.match url.to_s
    matches[6] || matches[5] if matches
  end

  def find_vimeo_id(url)
    matches = VIMEO_REGEX.match url.to_s
    matches[1] || matches[2] if matches
  end

  # Get YouTube video iframe from given URL
  def get_youtube_iframe(url, width, height)
    youtube_id = find_youtube_id url

    result = %(<iframe title="YouTube video player" width="#{width}"
	              height="#{height}" src="//www.youtube.com/embed/#{youtube_id}"
	              frameborder="0" allowfullscreen></iframe>)
    result.html_safe
  end

  def get_vimeo_iframe(url, width, height)
    vimeo_id = find_vimeo_id url

    result = %(<iframe title="YouTube video player" width="#{width}"
                height="#{height}" src="https://player.vimeo.com/video/#{vimeo_id}"
                frameborder="0" allowfullscreen></iframe>)
    result.html_safe
  end

  def privacy_icon(value)
    case value
    when 'friends' then 'friends'
    when 'only_me' then 'only-me'
    when 'custom' then 'custom'
    else 'public'
    end
  end

  def privacy_text(value)
    case value
    when 'friends' then 'Friends'
    when 'only_me' then 'Only Me'
    when 'custom' then 'Custom'
    else 'Public'
    end
  end

  def privacy_name(user, user_privilege, current_user)
    return user.full_name&.titleize if user_privilege || (user == current_user) || current_user.admin?

    user.display_id
  end

  def paper_title(paper)
    return paper&.title&.join(',') if paper&.title&.class == Array

    paper&.title&.gsub(/[\["\]]/, '')
  end

  def paper_auther_list(paper)
    return paper&.author_list unless paper&.author_list&.class == Array

    paper&.author_list&.join(',')
  end

  def request_sent(current_user, friend)
    current_user.request_sent?.include?(friend) || current_user.pending_friends.include?(friend)
  end

  def connected(current_user, friend)
    current_user.friends.include? (friend)
  end

  def user_has_applied_for_summit(user_id, summit_id)
    SummitApplication.where(user_id: user_id).where(summit_id: summit_id).present?
  end

  def user_type_titleize(user)
    titleize_without_underscore(user&.user_type)
  end

  def get_education_level(level)
    SchoolsUser.education_levels[level]
  end

  def titleize_without_underscore(str)
    str&.gsub("_", " ")&.titleize
  end

  def admin_sidebar_active_menu(url)
    params[:controller] == url ? 'active' : ''
  end

  def name_with_design
    "#{@user.full_name.humanize}, #{@user.user_type&.humanize}"
  end

  def is_company_user(user)
    user.manager_users.company_users.exists?
  end

  def is_research_center_users(user)
    user.manager_users.research_center_users.exists?
  end

  def research_summary_class(research_summary)
    research_summary.html_safe.length > 600 ? 'truncate-after-six-line' : ''
  end

  def rankings_received_by_user(company, user)
    company.rankings_received.by_user(user)
  end

  def rankings_received_by_company(company, user)
    user.rankings_received.by_company(company)
  end

  def pdf_viewer(pdf_url, options = {})
    iframe_options = options.fetch(:iframe_options, {})

    content_tag(:iframe, nil, {
      src: pdf_url,
      frameborder: 0,
      width: '100%',
      height: '500px'
    }.merge(iframe_options))
  end

  def email_sent_setatus(status)
    if status == 'opened'
      'blue'
    elsif status == 'delivered'
      'green'
    elsif status == 'first_opening'
      'yellow'
    elsif status == 'sent'
      'grey'
    elsif status == 'click'
      'light_blue'
    else
      'red'
    end
  end

  def get_user_status(invitee, invitable)
    case invitable.class.name
    when "Group" then invitable.group_users.find_by(user_id: invitee)&.status
    when "Community" then invitable.user_communities.find_by(user_id: invitee)&.status
    when "Company" then invitable.company_users.find_by(user_id: invitee)&.status
    when "School" then invitable.schools_users.find_by(user_id: invitee)&.status
    when "ResearchCenter" then invitable.research_centers_users.find_by(user_id: invitee)&.status
    else
      nil
    end
  end
end
