module AwesomeDelete
  module DeleteExtension
    def delete_collection deleted_ids, all_association_names = []
      return 0 if deleted_ids.blank?

      # Need not to set value for all_association_names, all_association_names will be auto filled
      # Not handle counter_cache or touch association in all_association_names
      if all_association_names.blank?
        find_all_association_names(all_association_names)
        all_association_names << self.name
      end

      options = { all_association_names: all_association_names }

      __delete_collection(deleted_ids, options)
    end

    def __delete_collection deleted_ids, options
      delete_assoicated_collection(deleted_ids, options)

      delete_self_collection(deleted_ids, options)
    end

    def delete_self_collection deleted_ids, options
      # cache data that is need to handle touch and counter_cache, because which will be gone after delete_all
      cache_ids_with_types_of_touch = get_ids_with_types(touch_associations, deleted_ids)
      cache_ids_with_types_of_counter_cache = get_ids_with_types(counter_cache_associations, deleted_ids)

      deleted_counter = where(id: deleted_ids).delete_all

      handle_touch cache_ids_with_types_of_touch, options
      handle_counter_cache cache_ids_with_types_of_counter_cache, options

      deleted_counter
    end

    def delete_assoicated_collection deleted_ids, options
      all_association_names = options[:all_association_names]

      deleted_associations.each do |association|
        association_class = association.klass

        # polymorphic
        if association.type
          association_class.delete_collection association_class.where(association.foreign_key => deleted_ids, association.type => self.name).pluck(:id), all_association_names
        else
          association_class.delete_collection association_class.where(association.foreign_key => deleted_ids).pluck(:id), all_association_names
        end
      end
    end

    def find_all_association_names names
      # Find all classes that will be deletded
      return [] if deleted_associations.blank?

      deleted_associations.each do |association|
        next if association.class_name.in?(names)

        names << association.class_name
        association.class_name.constantize.find_all_association_names(names)
      end
    end

    def get_ids_with_types assos, deleted_ids
      # polymorphic: { 'Post' => [1,3,4], 'Form' => [4,5,6] }
      # not polymorphic: [1, 2 ,3]
      # asso is BelongsToReflection

      assos.map do |asso|
        if asso.options[:polymorphic]
          where(id: deleted_ids).group(asso.foreign_type)
                                .pluck("#{asso.foreign_type}, array_agg(distinct #{asso.foreign_key})")
                                .to_h
        else
          where(id: deleted_ids).pluck(asso.foreign_key).uniq
        end
      end
    end

    def handle_touch data, options
      # touching one by one is to execute touch callbacks

      touch_associations.each_with_index do |asso, index|
        if asso.options[:polymorphic]
          types_with_ids = data[index]
          types_with_ids.each do |type, ids|
            next if options[:all_association_names].include?(type)

            type.constantize.where(id: ids).find_each(&:touch)
          end

        else
          next if options[:all_association_names].include?(asso.class_name)

          asso_ids = data[index]
          asso.klass.where(id: asso_ids).find_each(&:touch)
        end
      end
    end

    def handle_counter_cache data, options
      counter_cache_associations.each_with_index do |asso, index|
        if asso.options[:polymorphic]
          types_with_ids = data[index]
          types_with_ids.each do |type, ids|
            next if options[:all_association_names].include?(type)

            ids.each do |id|
              count = where(asso.foreign_key => id, asso.foreign_type => type).count
              type.constantize.where(id: id).update_all asso.counter_cache_column => count
            end
          end
        else
          next if options[:all_association_names].include?(asso.class_name)

          asso_ids = data[index]
          asso_ids.each do |id|
            count = where(asso.foreign_key => id).count
            asso.klass.where(id: id).update_all asso.counter_cache_column => count
          end
        end
      end
    end

    def deleted_associations
      return @deleted_associations if @deleted_associations

      @deleted_associations = reflect_on_all_associations.select do |asso|
        [:destroy, :delete_all, :delete].include? asso.options.deep_symbolize_keys[:dependent]
      end

      # STI: dependent destroy in subclass
      # TODO: in development mode, subclasses are not showing up due to lazy loading.
      if column_names.include? inheritance_column
        pluck("distinct #{inheritance_column}").each do |type|
          next if type.blank?

          subklass = type.constantize
          sub_deleted_associations = subklass.reflect_on_all_associations.select do |asso|
            [:destroy, :delete_all, :delete].include? asso.options.deep_symbolize_keys[:dependent]
          end

          @deleted_associations |= sub_deleted_associations
        end
      end

      @deleted_associations
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
  end
end
