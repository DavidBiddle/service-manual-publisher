class SlugMigrationsController < ApplicationController
  def index
    @migrations = SlugMigration.all
    if params[:completed].present?
      @migrations = @migrations.where(completed: params[:completed])
    end
  end

  def edit
    @slug_migration = SlugMigration.find(params[:id])
    @select_options = Guide.with_published_editions.map {|g| [g.slug, g.id] }
    @selected_guide_id = @slug_migration.guide.try(:id)
  end

  def update
    slug_migration = SlugMigration.find(params[:id])
    guide = Guide.find_by_id(params[:slug_migration][:guide])

    slug_migration.guide = guide
    slug_migration.completed = params[:save_and_migrate].present?

    ActiveRecord::Base.transaction do
      slug_migration.save!
      if slug_migration.completed?
        SlugMigrationPublisher.new.process(slug_migration)
        redirect_to slug_migration_path(slug_migration), notice: "Slug Migration has been completed"
      else
        redirect_to edit_slug_migration_path(slug_migration), notice: "Slug Migration has been saved"
      end
    end
  rescue
    @slug_migration = slug_migration
    @select_options = Guide.with_published_editions.map {|g| [g.slug, g.id] }
    @selected_guide_id = guide.try(:id)
    if slug_migration.completed?
      flash[:notice] = "Slug Migration has failed"
    end
    render action: :edit
  end

  def show
    @slug_migration = SlugMigration.find(params[:id])
  end
end
