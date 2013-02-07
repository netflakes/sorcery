module Sorcery
  module Model
    module Adapters
      module Neo4j
        def self.included(klass)
          klass.extend ClassMethods
          klass.send(:include, InstanceMethods)
        end

        module InstanceMethods
          def update_many_attributes(attrs)
            attrs.each do |name, value|
              self.send(:"#{name}=", value)
            end
            primary_key = self.class.primary_key
            self.class.where(:"#{primary_key}" => self.send(:"#{primary_key}")).update_all(attrs)
          end

          def update_single_attribute(name, value)
            update_many_attributes(name => value)
          end
        end
        
        module ClassMethods
          def column_name(attribute)
            return "LOWER(#{attribute})" if (@sorcery_config.downcase_username_before_authenticating)
            return "#{attribute}"
          end

          def find_by_credentials(credentials)
            @sorcery_config.username_attribute_names.each do |attribute|
              @user = all.query(attribute => credential_regex(credentials[0])).first
              break if @user
            end
            @user
          end

          def find_by_sorcery_token(token_attr_name, token)
            all.query("#{token_attr_name} = ?", token).first
          end

          def get_current_users
            config = sorcery_config

            all.query("#{config.last_activity_at_attribute_name} IS NOT NULL") \
            .query("#{config.last_logout_at_attribute_name} IS NULL OR #{config.last_activity_at_attribute_name} > #{config.last_logout_at_attribute_name}") \
            .query("#{config.last_activity_at_attribute_name} > ? ", config.activity_timeout.seconds.ago.utc.to_s(:db))
            
            #where("#{config.last_activity_at_attribute_name} IS NOT NULL") \
            #.where("#{config.last_logout_at_attribute_name} IS NULL OR #{config.last_activity_at_attribute_name} > #{config.last_logout_at_attribute_name}") \
            #.where("#{config.last_activity_at_attribute_name} > ? ", config.activity_timeout.seconds.ago.utc.to_s(:db))
          end
        end
      end
    end
  end
end#
