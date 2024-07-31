# frozen_string_literal: true

# messages
class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_conversation!, except: %i[load_message load_message_for_popup edit destroy]
  before_action :set_message, only: %i[edit destroy]
  skip_before_action :verify_authenticity_token,
                     only: %i[load_message create load_message_for_popup load_message_for_empty_popup]

  def new
    redirect_to conversation_path(@conversation) and return if @conversation

    @message = current_user.messages.build
  end

  def edit
    respond_to do |format|
      format.js
      format.html
    end
  end

  def create
    if @conversation.blank?
      @conversation = Conversation.create(conversation_type: Conversation.conversation_types[:direct])
      [params[:participant_id], params[:message][:user_id]].each do |id|
        @conversation.participants.create(user_id: id)
      end
    end
    @message = @conversation.messages.build(message_params)
    @message.save!

    flash[:success] = 'Your message was sent!'
    render json: true
    # redirect_to conversations_path
  end

  def load_message
    @message = Message.find(params[:message_id])
    @conversation = @message.conversation
  end

  def load_message_for_popup
    @message = Message.find(params[:message_id])
  end

  def load_message_for_empty_popup
    @message = Message.find(params[:message_id])
    @conversation = @message.conversation
    @grouped_messages = @conversation.messages.order('messages.created_at asc').group_by { |a| a.created_at.to_date }
  end

  def reset_message_box
    @message = Message.new
    @conversation = Conversation.find_by(id: params[:conversation_id])
    respond_to do |format|
      format.js
      format.html
    end
  end

  def destroy
    @message.destroy
  end

  private

  def message_params
    params.require(:message).permit(:body, :user_id)
  end

  def set_message
    @message = Message.find_by(id: params[:id])
    @conversation = @message.conversation
  end

  def find_conversation!
    if params[:participant_id]
      @participant = User.find_by(id: params[:participant_id])
      redirect_to(root_path) and return unless @participant

      @conversation = current_user.conversations.direct_conversation(@participant.id)
    else
      @conversation = current_user.conversations.find_by(id: params[:conversation_id])
      redirect_to(root_path) and return unless @conversation
    end
  end
end
