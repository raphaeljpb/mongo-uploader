# encoding: UTF-8

module MongoUploader

  module Mount

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def mongo_attachment(column)

        after_destroy "delete_#{column.to_s}".to_sym

        define_method("#{column.to_s}_id") do
          with_value(column) { |val| val.split("/").first rescue val }
        end

        define_method("#{column.to_s}=") do |_file|
          obj_id = self.class.mongo_storage.store(_file)
          write_attribute(column.to_sym, "#{obj_id}/#{_file.original_filename}")
        end

        define_method("#{column.to_s}") do
          return unless id = send("#{column.to_s}_id")
          self.class.mongo_storage.retrieve(id)
        end

        define_method("delete_#{column.to_s}") do
          return unless id = send("#{column.to_s}_id")
          self.class.mongo_storage.delete(id)
        end

        define_method("#{column.to_s}_url") do
           with_value(column) { |val| "/mongo/#{val}" }
        end

        define_method("#{column.to_s}_name") do
          with_value(column) { |val| val.split("/").last rescue val }
        end

        define_method("#{column.to_s}_present?") do
          read_attribute(column.to_sym).present?
        end

      end

      def mongo_storage
        @storage ||= MongoUploader::Storage.new()
      end

      def with_value(column, &block)
        return unless value = read_attribute(column.to_sym)
        yield value
      end

    end

  end

end