# frozen_string_literal: true

require "spec_helper"

describe "Action Authorization", type: :feature do
  include_context "with a feature"

  let(:manifest_name) { "proposals" }

  let!(:organization) do
    create(:organization, available_authorizations: [authorization])
  end

  let!(:proposal) { create(:proposal, feature: feature) }

  let!(:feature) do
    create(
      :proposal_feature,
      :with_creation_enabled,
      manifest: manifest,
      participatory_space: participatory_space,
      permissions: permissions
    )
  end

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  context "when using a handler authorization", with_authorization_workflows: ["dummy_authorization_handler"] do
    let(:authorization) { "dummy_authorization_handler" }

    context "and action authorized" do
      let(:permissions) do
        { create: { authorization_handler_name: "dummy_authorization_handler" } }
      end

      before do
        visit main_feature_path(feature)
        click_link "New proposal"
      end

      it "prompts user to authorize" do
        expect(page).to have_content("Authorization required")
        expect(page).to have_content("In order to perform this action, you need to be authorized with \"Example authorization\"")
      end

      it "redirects to authorization when modal clicked" do
        click_link "Authorize with \"Example authorization\""

        expect(page).to have_selector("h1", text: "Verify with Example authorization")
      end
    end

    context "and action authorized and authorization expired" do
      let(:permissions) do
        { create: { authorization_handler_name: "dummy_authorization_handler" } }
      end

      before do
        create(:authorization, name: "dummy_authorization_handler", user: user, granted_at: 1.month.ago)
        visit main_feature_path(feature)
        click_link "New proposal"
      end

      it "prompts user to check her authorization status" do
        expect(page).to have_content("Authorization has expired")
        expect(page)
          .to have_content("Your authorization has expired. In order to perform this action, you need to be reauthorized with \"Example authorization\"")
      end

      it "redirects to resume authorization when modal clicked" do
        click_link "Reauthorize with \"Example authorization\""

        expect(page).to have_content("Verify with Example authorization")
      end
    end

    context "when action not authorized" do
      let(:permissions) { nil }

      before do
        visit main_feature_path(feature)
        click_link "New proposal"
      end

      it "goes directly to action" do
        expect(page).to have_selector("h2", text: "NEW PROPOSAL")
      end
    end
  end

  context "when using a workflow authorization", with_authorization_workflows: ["dummy_authorization_workflow"] do
    let(:authorization) { "dummy_authorization_workflow" }

    context "and action authorized" do
      let(:permissions) do
        { create: { authorization_handler_name: "dummy_authorization_workflow" } }
      end

      before do
        visit main_feature_path(feature)
        click_link "New proposal"
      end

      it "prompts user to authorize" do
        expect(page).to have_content("Authorization required")
        expect(page).to have_content("In order to perform this action, you need to be authorized with \"Dummy authorization workflow\"")
      end

      it "redirects to authorization when modal clicked" do
        click_link "Authorize with \"Dummy authorization workflow\""

        expect(page).to have_content("DUMMY VERIFICATION")
      end
    end

    context "and action authorized and authorization already started" do
      let(:permissions) do
        { create: { authorization_handler_name: "dummy_authorization_workflow" } }
      end

      before do
        create(:authorization, :pending, name: "dummy_authorization_workflow", user: user)
        visit main_feature_path(feature)
        click_link "New proposal"
      end

      it "prompts user to check her authorization status" do
        expect(page).to have_content("Authorization is still in progress")
        expect(page)
          .to have_content("In order to perform this action, you need to be authorized with \"Dummy authorization workflow\", but your authorization is still in progress")
      end

      it "redirects to resume authorization when modal clicked" do
        click_link "Check your \"Dummy authorization workflow\" authorization progress"

        expect(page).to have_content("CONTINUE YOUR VERIFICATION")
      end
    end

    context "and action authorized and authorization expired" do
      let(:permissions) do
        { create: { authorization_handler_name: "dummy_authorization_workflow" } }
      end

      before do
        create(:authorization, name: "dummy_authorization_workflow", user: user, granted_at: 1.month.ago)
        visit main_feature_path(feature)
        click_link "New proposal"
      end

      it "prompts user to check her authorization status" do
        expect(page).to have_content("Authorization has expired")
        expect(page)
          .to have_content("Your authorization has expired. In order to perform this action, you need to be reauthorized with \"Dummy authorization workflow\"")
      end

      it "redirects to resume authorization when modal clicked" do
        click_link "Reauthorize with \"Dummy authorization workflow\""

        expect(page).to have_content("DUMMY VERIFICATION ENGINE")
      end
    end

    context "when action not authorized" do
      let(:permissions) { nil }

      before do
        visit main_feature_path(feature)
        click_link "New proposal"
      end

      it "goes directly to action" do
        expect(page).to have_selector("h2", text: "NEW PROPOSAL")
      end
    end
  end
end
