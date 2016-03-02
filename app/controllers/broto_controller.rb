class BrotoController < ActionController::Base

  def baction
    @response_code = 500
    sekret        = "s3kret"
    response      = {}
    if params[:passw0rd] != sekret # make this a config item
      # response = {"error" => "authentication failed"}
      response = broto_error_message("authentication failed", 401)
    else
      iid          = params.require(:iid)
      broto_action = params.require(:broto_action)
      begin
        @merge_request = MergeRequest.find_by_iid(iid)
      rescue ActiveRecord::RecordNotFound => e
        @merge_request = false
      end
      if !@merge_request
        response = broto_error_message "merge request with iid #{iid} not found"
      elsif (@merge_request.target_branch != "sprout")
        response = broto_error_message "action requested for non-sprout branch"
      else
        response = case broto_action
                   when "nightly"
	             # FIXME: check for good state
                     @merge_request.broto_enter_nightly
                     broto_success_message(@merge_request)
                   when "close"
	             # FIXME: check for good state
                     @merge_request.broto_close
  	             broto_success_message(@merge_request)
                   when  "merge"
                     @merge_request.broto_mark_as_merged
	  	     broto_success_message(@merge_request)
                   when "log"
                     broto_error_message "logging unimplemented"
                   else
                     broto_error_message "invalid action"
                   end
      end
    end
    respond_to do |format|
      format.json {render json: response, status: @response_code}
    end
  end

  private

  def broto_success_message (mr)
    @response_code = 200
    {mr: mr.state}
  end

  def broto_error_message(msg, code=@response_code)
    @response_code = code
    {error: msg}
  end

end
