class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    alias_action :create, :new, :to => :new_create
    alias_action :update, :edit, :to => :edit_update

    user ||= User.new # guest user (not logged in)
    if user.new_record?
      can :index, Organization
    else
      if user.current_user_role_name.try(:to_sym) == :admin
        can :manage, :all
      elsif user.roles.present?
        # cannot :read, :all
        # cannot :manage, :all

        # user.roles.find(user.current_user_role_id).rpermissions.where(controller_resource: "Organization").each do |rpermission|
        #   can rpermission.controller_action.to_sym, rpermission.controller_resource.constantize, id: user.organization.try(:id)
        # end

        # user.roles.find(user.current_user_role_id).rpermissions.where(controller_resource: "User").each do |rpermission|
        #   can rpermission.controller_action.to_sym, rpermission.controller_resource.constantize, id: ((user.organization && user.organization.user_ids.present?) ? user.organization.user_ids : user.id)
        # end
        Role.find_by_id(user.current_user_role_id).cached_rpermissions.each do |rpermission|
          can rpermission.cached_subject_actions.map { |s| s.name.to_sym }, rpermission.subject_class.name.classify.constantize, Hash[ rpermission.subject_attributes.map { |a| [ a.name.to_sym, a.value ] } ]

        end

      else
        # can [:update, :initiate_user_profile_edit, :upload_avatar], User, id: user.id
        can :index, all


      end
    end
    #
    # The first argument to `can` is the action you are giving the user 
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. 
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
    # aliasing
    # can :crud, User
    # can :invite, User
  end
end
