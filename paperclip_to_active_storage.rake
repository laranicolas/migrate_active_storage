# TODO: Future delete only used for Active Storage migration.
namespace :paperclip_to_as do
  desc 'Migrate vendor logo images.'
  task :migrate_vendor_logos => :environment do |task, args|
    process_model(VendorLogo, 'upload')
  end

  desc 'Migrate buyer logo images.'
  task :migrate_buyer_logos => :environment do |task, args|
    process_model(BuyerLogo, 'upload')
  end

  desc 'Migrate creative images.'
  task :migrate_creatives => :environment do |task, args|
    process_model(CreativeUpload, 'upload')
  end

  desc 'Migrate files.'
  task :migrate_files => :environment do |task, args|
    process_model(FileUpload, 'upload')
  end

  desc 'Migrate company logos.'
  task :migrate_company_logos => :environment do |task, args|
    process_model(CompanyLogo, 'upload')
  end

  def process_model(klass, attribute)
    unless klass.new.respond_to?("active_storage_#{attribute}=") && klass.new.respond_to?("paperclip_#{attribute}=")
      raise "#{klass}##{attribute} isn't configured to be migrated"
    end

    records_to_migrate(klass, attribute).find_each do |record|
      Resque.enqueue(MigrateToActiveStorage, klass.name, record.id, attribute)
    end
  end

  def records_to_migrate(klass, attribute)
    klass.left_outer_joins(:"#{attribute}_attachment").
      where(active_storage_attachments: {id: nil}).
      where.not("#{attribute}_file_name" => nil)
  end
end
