# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.super_admin?
      can :manage, :all
    elsif user.regional_admin?
      can :manage, Madrassa, region_id: user.region_id
      can :manage, User, role: 'head_teacher', madrassa: { region_id: user.region_id }
      can :manage, User, role: 'teacher', madrassa: { region_id: user.region_id }
      can :manage, Standard, madrassa: { region_id: user.region_id }
      cannot :manage, Message
    elsif user.head_teacher?
      can %i[read update], Madrassa, id: user.madrassa_id
      can :manage, User, role: 'teacher', madrassa_id: user.madrassa_id
      can :manage, Standard, madrassa_id: user.madrassa_id
      can :manage, Message
      can :update, UserMessage
    elsif user.teacher?
      can :read, Madrassa, id: user.madrassa_id
      can %i[read], Standard, id: user.standard_ids
      cannot :read, Message
    end
  end
end
