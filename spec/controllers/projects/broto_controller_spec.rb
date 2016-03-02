require 'spec_helper'
require "rspec/json_expectations"

describe Projects::BrotoController do
  let(:project) { create(:project) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

  def expect_error(error_msg)
    expect(response.body).to include_json(error: error_msg)
    expect(response).not_to be_success
  end

  def expect_success(state)
    expect(response.body).to include_json(mr: state)
    expect(response).to be_success
  end

  def go(action, params={})
    post :baction, params.merge({ broto_action: action, format: :json })
  end

  describe '#baction' do
    context 'with the wrong password' do
      it 'is rejected' do
        go("merge", {passw0rd: "wr0ng"})
        expect(response.body).to include_json(error: "authentication failed")
        expect(response).not_to be_success
      end
    end
    context 'with the correct password' do
      let(:pwd) { {passw0rd: "s3kret"} }
      it 'does not reject it' do
        go("merge", pwd.merge({iid: merge_request.iid}))
        expect(response.body).not_to include_json(error: "authentication failed")
      end

      context 'with an iid that is not found' do
        let(:invalid_id){-merge_request.iid}
        it 'is rejected' do
          go("nightly", pwd.merge({iid: invalid_id}))
          expect_error("merge request with iid #{invalid_id} not found")
        end
        context 'with a target branch not being sprout' do
          it 'is rejected' do
            go("nightly", pwd.merge({iid: merge_request.iid}))
            expect_error("action requested for non-sprout branch")
          end
        end
      end
      context 'with sprout as a target branch' do
        before do
          merge_request.target_branch = "sprout"
          merge_request.save!
        end
        context 'with an invalid action' do
          it 'is rejected' do
            go("waka", pwd.merge({iid: merge_request.iid}))
            expect_error("invalid action")
          end
        end
        context 'with a valid action' do
          def do_valid_action(action, state)
            go(action, pwd.merge({iid: merge_request.iid}))
            merge_request.reload
            expect(merge_request.state).to eq state
            expect_success state
          end
          context 'with nightly action' do
            it 'returns brotocheck' do
              do_valid_action("nightly", "brotocheck")
            end
          end
          context 'with close action' do
            it 'returns brotocheck' do
              do_valid_action("close", "opened")
            end
          end
          context 'with merge action' do
            it 'returns brotocheck' do
              do_valid_action("merge", "opened")
            end
          end
          context 'with log action' do
            it 'fails as unimplemented' do
              go("log", pwd.merge({iid: merge_request.iid}))
              expect_error("logging unimplemented")
            end
          end
        end
      end
    end
  end
end
