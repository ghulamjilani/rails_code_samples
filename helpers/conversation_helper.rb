module ConversationHelper
  def conversation_picture(conversation)
    if conversation.direct?
      if conversation.with_picture(current_user).present?
        image_tag(conversation.with_picture(current_user).image)
      else
        "<span class='messages_empty_avatar_holder'><span class='messages_avatar_letters'>#{current_user.full_name&.chr}</span></span>"
      end
    elsif conversation&.conversationable&.picture.present?
      image_tag(conversation&.conversationable&.picture&.image, width: 32, height: 32)
    else
      "<span class='messages_empty_avatar_holder'><span class='messages_avatar_letters'>#{conversation&.conversationable&.name&.chr}</span></span>"
    end
  end

  def conversation_name(conversation)
    if conversation.direct?
      conversation.with(current_user)
    else
      conversation.name
    end
  end

  def conversation_other_user_id(conversation)
    conversation.with_other_user(current_user).id if conversation.direct?
  end

  def conversation_last_message(conversation)
    conversation.messages&.first&.body[0..40]&.gsub(/\s\w+\s*$/, '...') if conversation.messages&.first
  end

  def conversation_searched_message(conversation)
    conversation.messages.filter_by_body(params[:search]).first&.body[0..40]&.gsub(/\s\w+\s*$/, '...')
  end

  def conversation_date(conversation)
    if conversation.messages.first
      last_message_date = if current_user.timezone.present?
                            conversation.messages.first.created_at.in_time_zone(current_user.timezone)
                          else
                            conversation.messages.first.created_at
                          end
    else
      last_message_date = DateTime.now()
    end
    if last_message_date.to_date == Date.today
      conversation_datetime_format(last_message_date)
    elsif last_message_date.to_date == (Date.today - 1.day)
      'Yesterday'
    elsif last_message_date.to_date.year == Date.today.year
      last_message_date.strftime('%-m/%-e')
    elsif last_message_date.to_date.year != Date.today.year
      last_message_date.strftime('%-m/%-e/%Y')
    end
  end

  def conversation_datetime_format(datetime)
    datetime.strftime('%l:%M %p')
  end

  def group_management_url(object)
    object ? send("chat_management_#{object&.class&.name&.downcase}_path", object) : "javascript:void(0)"
  end

  def files_link(object)
    path = object&.is_a?(Group) ? files_group_path(object) : files_community_path(object)
    link_to('(View all files)', path, class: 'small')
  end

  def conversation_created_by(object)
    conversation_admins = object.class.name.downcase + '_admins'
    "#{object.send(conversation_admins)&.first&.user&.name} on #{object.created_at&.strftime('%B %d, %Y')}"
  end

end
