module Model
    API_PATH = "/payments-api/rest/v4.3"

    def self.included(base)
        base.send :extend, ClassMethods
    end

    def save 
        verb = new? ? "post" : "put"
        @url ||= new? ? "#{API_PATH}/#{@resource}" : "#{API_PATH}/#{@resource}/#{base.id}"
        resp = http_call(verb, @url, base.marshal_dump)

        if resp.is_a?(Array)
          error = {field: resp[0], message: resp[1]}
          self.errors << error
          false
        else
          base.marshal_load resp
          true
        end
    end

    def load
        resp = http_call("get", "#{API_PATH}/#{@resource}/#{self.attr.id}")
        base.marshal_load resp
    end

    def destroy
        @id ||= self.attr.id
        @url ||= "#{API_PATH}/#{@resource}/#{@id}"
        resp = http_call("delete", @url)
        base.marshal_load resp unless resp.is_a? Array
        resp
    end

    def new?
        base.id.nil?
    end

    def method_missing(method_name, *arguments, &block)
        if base.marshal_dump.include?(method_name.to_s.strip.to_sym) || method_name.match(/.*=$/)
           base.send(method_name.to_s.strip, *arguments, &block)
        else
           super
        end
    end


    # xxxxxxxxxxxxxxxxx validations xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

    def validate_presence_of(field)
        if (self.attr.send(field.to_s).nil? or self.attr.send(field.to_s) == "")
            error = {}
            error[:field] = field
            error[:message] = "#{field} can't be blank"
            self.errors << error
        end
    end

    def validate_lenght_of(field, lenght)
        unless self.attr.send(field.to_s).nil?
          if self.attr.send(field.to_s).length != lenght
              error = {}
              error[:field] = field
              error[:message] = "lenght of #{field} should be #{lenght}"
              self.errors << error
          end
        end
    end

    def validates_format_of(field, regexp, message)
        unless self.attr.send(field.to_s).nil? 
              unless self.attr.send(field.to_s).match regexp
               self.errors << { field: field, message: message }
              end
        end
    end

    # Class Methods
    module ClassMethods
        def find(id)
            resp = self.new
            json = resp.http_call("get", "#{API_PATH}/#{resp.resource}/#{id}")

            unless json["type"] == "NOT_FOUND"
              self.new json
            else
              nil
            end
        end

        def create(params)
            http_call("post", "#{API_PATH}/#{@resource}", base.marshal_dump)
        end
    end
end
