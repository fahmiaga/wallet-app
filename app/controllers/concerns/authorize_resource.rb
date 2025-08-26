module AuthorizeResource
  extend ActiveSupport::Concern
  included do
    helper_method :authorized
  end

  private
  def authorized(owner: nil)
     unless current_user == owner
      render json: { error: "Unauthorized" }, status: :forbidden and return
     end
  end
end
