module ApplicationHelper
  def facebook_login_path
    "/auth/facebook"
  end

  def twitter_login_path
    "/auth/twitter"
  end

  def current_user
    return @current_user unless @current_user.nil?

    return nil unless session.key?(:user_id)

    @current_user = User.find_by_id(session[:user_id])
    return @current_user
  end

  def logged_in?
    return !current_user.nil?
  end

  def swapping_open?
    return !ENV["SWAPS_CLOSED"]
  end

  def login_open?
    swapping_open? || params[:opensesame]
  end

  def canonical_name(name)
    return nil if name.nil?
    return name.parameterize(separator: "_")
  end

  def github_url
    return "https://github.com/swapmyvote/swapmyvote/"
  end

  def mobile_verified?
    return current_user.try(:mobile_phone).try(:verified)
  end

  def mobile_needs_verification?
    return current_user.try(:mobile_phone) &&
           !current_user.mobile_phone.verified
  end
end
