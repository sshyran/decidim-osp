# frozen_string_literal: true

module Decidim
  # Exposes the scopes text search so users can choose a scope writing its name.
  class ScopesController < Decidim::ApplicationController
    def picker
      authorize! :pick, Scope

      title = params[:title] || t("decidim.scopes.picker.title", field: params[:field]&.downcase)
      root = Scope.find(params[:root]) if params[:root]
      context = root ? { root: root.id, title: title } : { title: title }
      required = params[:required] && params[:required] != "false"
      if params[:current]
        current = (root&.descendants || current_organization.scopes).find_by(id: params[:current]) || root
        scopes = current.children
        parent_scopes = current.part_of_scopes(root)
      else
        current = root
        scopes = root&.children || Scope.top_level
        parent_scopes = [root].compact
      end
      render :picker, layout: nil, locals: { required: required, title: title, root: root, current: current, scopes: scopes.order(name: :asc),
                                             parent_scopes: parent_scopes, global_value: params[:global_value], context: context }
    end
  end
end
