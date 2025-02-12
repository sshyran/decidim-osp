# frozen_string_literal: true

require "spec_helper"

describe "Explore results", versioning: true, type: :feature do
  include_context "with a feature"

  let(:manifest_name) { "accountability" }
  let(:results_count) { 5 }
  let!(:scope) { create :scope, organization: organization }
  let!(:results) do
    create_list(
      :result,
      results_count,
      feature: feature
    )
  end

  before do
    visit path
  end

  describe "home" do
    let(:path) { decidim_participatory_process_accountability.root_path(participatory_process_slug: participatory_process.slug, feature_id: feature.id) }

    it "shows categories and subcategories with results" do
      participatory_process.categories.each do |category|
        results_count = Decidim::Accountability::ResultsCalculator.new(feature, nil, category.id).count
        if !category.subcategories.empty? || results_count.positive?
          expect(page).to have_content(translated(category.name))
        end
      end
    end
  end

  describe "index" do
    let(:path) { decidim_participatory_process_accountability.results_path(participatory_process_slug: participatory_process.slug, feature_id: feature.id) }

    it "shows all results for the given process and category" do
      expect(page).to have_selector(".card--list__item", count: results_count)

      results.each do |result|
        expect(page).to have_content(translated(result.title))
      end
    end
  end

  describe "show" do
    let(:path) { decidim_participatory_process_accountability.result_path(id: result.id, participatory_process_slug: participatory_process.slug, feature_id: feature.id) }
    let(:results_count) { 1 }
    let(:result) { results.first }

    it "shows all result info" do
      expect(page).to have_i18n_content(result.title)
      expect(page).to have_i18n_content(result.description)
      expect(page).to have_content(result.reference)
    end

    context "when it has no versions" do
      before do
        result.versions.destroy_all
        visit current_path
      end

      it "does not show version data" do
        expect(page).not_to have_content("VERSION NUMBER")
      end
    end

    context "when it has some versions" do
      it "does shows version data" do
        expect(page).to have_content("VERSION NUMBER 1")
      end
    end

    context "without category or scope" do
      it "does not show any tag" do
        expect(page).not_to have_selector("ul.tags.tags--result")
      end
    end

    context "with a category" do
      let(:result) do
        result = results.first
        result.category = create :category, participatory_space: participatory_process
        result.save
        result
      end

      it "shows tags for category" do
        expect(page).to have_selector("ul.tags.tags--result")
        within "ul.tags.tags--result" do
          expect(page).to have_content(translated(result.category.name))
        end
      end
    end

    context "with a scope" do
      let(:result) do
        result = results.first
        result.scope = create :scope, organization: organization
        result.save
        result
      end

      it "shows tags for scope" do
        expect(page).to have_selector("ul.tags.tags--result")
        within "ul.tags.tags--result" do
          expect(page).to have_content(translated(result.scope.name))
        end
      end
    end

    context "when a proposal has comments" do
      let(:result) { results.first }
      let(:author) { create(:user, :confirmed, organization: feature.organization) }
      let!(:comments) { create_list(:comment, 3, commentable: result) }

      before do
        visit current_path
      end

      it "shows the comments" do
        comments.each do |comment|
          expect(page).to have_content(comment.body)
        end
      end
    end

    context "with linked proposals" do
      let(:proposal_feature) do
        create(:feature, manifest_name: :proposals, participatory_space: result.feature.participatory_space)
      end
      let(:proposals) { create_list(:proposal, 3, feature: proposal_feature) }
      let(:proposal) { proposals.first }

      before do
        result.link_resources(proposals, "included_proposals")
        visit current_path
      end

      it "shows related proposals" do
        proposals.each do |proposal|
          expect(page).to have_content(proposal.title)
          expect(page).to have_content(proposal.author.name)
          expect(page).to have_content(proposal.votes.size)
        end
      end

      it "the result is mentioned in the proposal page" do
        click_link proposal.title
        expect(page).to have_i18n_content(result.title)
      end
    end

    context "with linked meetings" do
      let(:meeting_feature) do
        create(:feature, manifest_name: :meetings, participatory_space: result.feature.participatory_space)
      end
      let(:meetings) { create_list(:meeting, 3, feature: meeting_feature) }
      let(:meeting) { meetings.first }

      before do
        result.link_resources(meetings, "meetings_through_proposals")
        visit current_path
      end

      it "shows related meetings" do
        meetings.each do |meeting|
          expect(page).to have_i18n_content(meeting.title)
          expect(page).to have_i18n_content(meeting.description)
        end
      end

      it "the result is mentioned in the meeting page" do
        click_link translated(meeting.title)
        expect(page).to have_i18n_content(result.title)
      end
    end

    context "when filtering" do
      before do
        create(:result, feature: feature, scope: scope)
        visit_feature
      end

      context "when the process has a linked scope" do
        before do
          participatory_process.update_attributes(scope: scope)
          visit current_path
        end

        it "enables filtering by scope" do
          within ".scope-filters" do
            expect(page).not_to have_content(/Scopes/i)
          end
        end
      end

      context "when the process has no linked scope" do
        before do
          participatory_process.update_attributes(scope: nil)
          visit current_path
        end

        it "enables filtering by scope" do
          within ".scope-filters" do
            expect(page).to have_content(/Scopes/i)
          end
        end
      end
    end
  end
end
