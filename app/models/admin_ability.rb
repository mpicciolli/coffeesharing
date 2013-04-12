class AdminAbility
  include CanCan::Ability
 
  def initialize(user)
    user ||= AdminUser.new
    
    # A superadmin can do the following:
    if user.role?('superadmin')
      can :manage, AdminUser
    end
    
    # A moderator/admin can do the following:
    if user.role?('moderator')
      can :manage, Place
    end
    
    # Guest / User / BusinessOwners
    can :read, Place
  end
end