module PaperclipToActiveStorage

  def has_paperclip_attachment_with_active_storage(attribute, paperclip_options)
    has_one_attached attribute
    has_attached_file attribute, paperclip_options

    # Copied from Active Storage
    define_method "active_storage_#{attribute}" do
      active_storage_attached ||= {}
      active_storage_attached[:"#{attribute}"] ||= ActiveStorage::Attached::One.new("#{attribute}", self)
    end

    define_method "active_storage_#{attribute}=" do |attachable|
      attachment_changes["#{attribute}"] = if attachable.nil?
        ActiveStorage::Attached::Changes::DeleteOne.new("#{attribute}", self)
      else
        ActiveStorage::Attached::Changes::CreateOne.new("#{attribute}", self, attachable)
      end
    end

    # Copied from Paperclip
    define_method "paperclip_#{attribute}=" do |attachable|
      send(attribute).assign(attachable)
    end

    define_method "#{attribute}=" do |attachable|
      public_send("active_storage_#{attribute}=", attachable)
      public_send("paperclip_#{attribute}=", attachable)
    end
  end
end
