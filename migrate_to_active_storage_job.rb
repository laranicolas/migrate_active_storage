class MigrateToActiveStorage
  @queue = :migrate_to_active_storage

  def self.migrate(klass, record, attribute)
    tempfile = Tempfile.new
    record.with_lock do
      return if record.public_send("#{attribute}_attachment").present?
      paperclip_attachment = record.public_send(attribute)
      paperclip_attachment.copy_to_local_file(:original, tempfile.path)
      if tempfile.size > 0
        tempfile.rewind
        record.public_send("active_storage_#{attribute}=", {
          io: tempfile,
          key: record.active_storage_key,
          filename: paperclip_attachment.original_filename,
          content_type: paperclip_attachment.content_type,
          identify: false
        })
        record.save!
      else
        record.upload.destroy
      end
    end
  ensure
    tempfile.close
    if tempfile.size > 0
      Resque.enqueue(ResizeImagesJob, record.upload_attachment.id, Upload::FORMATS[:thumb])
      if klass == CreativeUpload || klass == FileUpload
        Resque.enqueue(ResizeImagesJob, record.upload_attachment.id, Upload::FORMATS[:creative_thumb])
      end
    end
  end

  def self.perform(klass_name, klass_id, attribute)
    klass = klass_name.constantize
    record = klass.find(klass_id)
    migrate(klass, record, attribute)
  end
end
