module AwesomeDelete
  module DeleteExtension
    def delete_collection ids, all_associations_name = []
      return true if ids.blank?

      #Need not to set value for all_associations_name
      #Not handle counter_cache or touch association in all_associations_name
      if all_associations_name.blank?
        all_associations_name = get_associations_name << self.name
      end

      delete_assoicated_collection(ids, deleted_associations, all_associations_name)

      # STI
      if column_names.include? inheritance_column
        where(id: ids).pluck(inheritance_column).uniq.each do |type|
          subklass = type.constantize
          subklass.delete_self_collection(ids, all_associations_name)
          delete_assoicated_collection(ids, subklass.deleted_associations - deleted_associations, all_associations_name)
        end
      else
        delete_self_collection(ids, all_associations_name)
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
                                        asso.options.deep_symbolize_keys[:counter_cache]
                                      end
    end

    def delete_self_collection ids, all_associations_name
      #touch
      need_handle_touch_associations = touch_associations.select do |asso|
                                         !all_associations_name.include?(asso.class_name)
                                       end
      cache_ids_with_types_of_touch = get_ids_with_types(need_handle_touch_associations)

      #counter_cache
      need_handle_counter_cache_associations = counter_cache_associations.select do |asso|
                                                 !all_associations_name.include?(asso.class_name)
                                               end
      cache_ids_with_types_of_counter_cache = get_ids_with_types(need_handle_counter_cache_associations)

      execute_callbacks(ids)

      handle_touch(need_handle_touch_associations, cache_ids_with_types_of_touch)
      handle_counter_cache(need_handle_counter_cache_associations, cache_ids_with_types_of_counter_cache)
    end

    def delete_assoicated_collection ids, associations, all_associations_name
      associations.each do |association|
        association_class = association.klass

        #polymorphic
        if association.type
          association_class.delete_collection association_class.where(association.foreign_key => ids, association.type => self.name).pluck(:id), all_associations_name
        else
          association_class.delete_collection association_class.where(association.foreign_key => ids).pluck(:id), all_associations_name
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

    def get_ids_with_types associations
      associations.map do |asso|
        if asso.options[:polymorphic]
          where(id: ids).pluck(asso.foreign_type, asso.foreign_key).uniq
        else
          where(id: ids).pluck(asso.foreign_key).uniq
        end
      end
    end

    def execute_callbacks ids
      #overwriting this method may be a better choice
      collection = where(id: ids).to_a
      befores = _destroy_callbacks.select { |callback| callback.kind == :before }
      afters = _destroy_callbacks.select { |callback| callback.kind == :after }
      commits = _commit_callbacks.select do |callback|
        ifs = callback.instance_variable_get('@if')
        ifs.empty? || ifs.include?("transaction_include_any_action?([:destroy])")
      end

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
      commits.each do |callback|
        case callback.filter
        when Symbol
          collection.each { |item| item.send callback.filter }
        end
      end
    end

    def handle_touch associations, ids_with_types
      associations.each_with_index do |asso, index|
        if asso.options[:polymorphic]
          types_ids = ids_with_types[index]
          types = types_ids.map(&:first).uniq
          types.each do |type|
            type_ids = types_ids.select { |type_id| type_id.first == type }.map(&:last).uniq.compact
            type.constantize.where(id: type_ids).map(&:touch)
          end
        else
          asso_ids = ids_with_types[index]
          asso.klass.where(id: asso_ids).map(&:touch)
        end
      end
    end

    def handle_counter_cache associations, ids_with_types
      associations.each_with_index do |asso, index|
        if asso.options[:polymorphic]
          types_ids = ids_with_types[index]
          types = types_ids.map(&:first).uniq
          types.each do |type|
            type_ids = types_ids.select { |type_id| type_id.first == type }.map(&:last).uniq.compact
            type_ids.each do |id|
              type.constantize.where(id: id).update_all asso.counter_cache_column => where(asso.foreign_key => id).count
            end
          end
        else
          asso_ids = ids_with_types[index]
          asso_ids.each do |id|
            asso.klass.where(id: id).update_all asso.counter_cache_column => where(asso.foreign_key => id).count
          end
        end
      end
    end
  end
end