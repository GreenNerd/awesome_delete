module AwesomeDelete
  module DeleteExtension
    def delete_collection ids, all_associations_name = []
      return true if ids.blank?

      #Not handle counter_cache or touch in all_associations_name
      @@all_associations_name = all_associations_name

      if @@all_associations_name.blank?
        @@all_associations_name = get_associations_name << self.name
      end

      delete_assoicated_collection(ids, deleted_associations)

      # STI
      if column_names.include? inheritance_column
        where(id: ids).pluck(inheritance_column).uniq.each do |type|
          subklass = type.constantize
          subklass.delete_self_collection(ids)
          delete_assoicated_collection(ids, subklass.deleted_associations - deleted_associations)
        end
      else
        delete_self_collection(ids)
      end
    end

    def deleted_associations
      @deleted_associations ||= reflect_on_all_associations.select do |asso|
                                  [:destroy, :delete_all].include? asso.options.deep_symbolize_keys[:dependent]
                                end
    end

    def touch_associations
      @touch_associations ||= reflect_on_all_associations.select do |asso|
                                asso.options.deep_symbolize_keys[:touch]
                              end
    end

    def counter_cache_associations
      @counter_cache_associations ||= reflect_on_all_associations.select do |asso|
                                        asso.options.deep_symbolize_keys[:counter_cahce]
                                      end
    end

    def delete_self_collection ids
      #touch
      need_handle_touch_associations = touch_associations.select do |asso|
                                         !@@all_associations_name.include?(asso.class_name)
                                       end
      need_handle_touch_associations.each do |asso|
        if asso.options[:polymorphic]
          types_ids = where(id: ids).pluck(asso.foreign_type, asso.foreign_key).uniq
          types = types_ids.map(&:first).uniq
          types.each do |type|
            type_ids = types_ids.select { |type_id| type_id.first == type }.map(&:last).uniq.compact
            type.constantize.where(id: type_ids).update_all updated_at: Time.now
          end
        else
          asso.klass.where(id: where(id: ids).pluck(asso.foreign_key)).update_all updated_at: Time.now
        end
      end

      #counter_cache
      need_handle_counter_cache_associations = counter_cache_associations.select do |asso|
                                                 !@@all_associations_name.include?(asso.class_name)
                                               end
      need_handle_counter_cache_associations.each do |asso|
        if asso.options[:polymorphic]
          types_ids = where(id: field_ids).pluck(asso.foreign_key, asso.foreign_type).uniq
          types = types_ids.map(&:first).uniq
          types.each do |type|
            ids = types_ids.select { |type_id| type_id.first == type }.map(&:last).uniq.compact
            ids.each do |id|
              associated_object = type.constantize.find_by id: id
              associated_object && associated_object.update(asso.counter_cache_column => where(asso.foreign_key => id).count)
            end
          end
        else
          asso_ids = where(id: ids).pluck(asso.foreign_key).uniq.compact
          asso_ids.each do |id|
            associated_object = asso.klass.find_by id: id
            associated_object && associated_object.update(asso.counter_cache_column => where(asso.foreign_key => id).count)
          end
        end
      end

      #execute callbacks
      collection = where(id: ids).to_a
      befores = _destroy_callbacks.select { |callback| callback.kind == :before }
      afters = _destroy_callbacks.select { |callback| callback.kind == :after }

      befores.each do |callback|
        case callback.filter
        when Symbol
          collection.each { |item| item.send callback.filter }
        end
      end
      where(id: ids).delete_all
      afters.each do |callback|
        case callback.filter
        when Symbol
          collection.each { |item| item.send callback.filter }
        end
      end
    end

    def delete_assoicated_collection ids, associations
      associations.each do |association|
        association_class = association.klass

        #polymorphic
        if association.type
          association_class.delete_collection association_class.where(association.foreign_key => ids, association.type => self.name).pluck(:id), @@all_associations_name
        else
          association_class.delete_collection association_class.where(association.foreign_key => ids).pluck(:id), @@all_associations_name
        end
      end
    end

    def get_associations_name
      return [] if deleted_associations.blank?
      associations_name = []

      deleted_associations.each do |association|
        associations_name << association.class_name
        associations_name += association.class_name.constantize.get_associations_name
      end
      associations_name
    end
  end
end