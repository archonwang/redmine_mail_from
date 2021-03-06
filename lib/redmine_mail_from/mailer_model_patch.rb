require_dependency 'mailer'

module RedmineMailFrom
  module MailerModelPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :mail, :patch
      end
    end
  end

  module InstanceMethods
    def mail_with_patch(headers={}, &block)

      placeholder = {
        '%f' => @author ? @author.firstname : nil,
        '%l' => @author ? @author.lastname : nil,
        '%m' => (@author && @author.mail && !@author.pref.hide_mail) ?
        @author.mail : nil,
        '%u' => @author ? @author.login : nil
      }

      from = ''

      Setting.mail_from.split(/\s*::\s*/).each do |s|
        nerr = 0

        placeholder.each do |key, val|
          next unless s.match(/#{key}/)

          if val.nil? then nerr += 1 end

          s.gsub!(/#{key}/, val || '')
        end

        from = s

        break if nerr == 0
      end

      host = Setting.host_name.split(/\//).first

      if @issue
        listid = "<#{@issue.project.identifier}.#{host}>"
      else
        listid = "<#{host}>"
      end

      headers['From'] = from
      headers['List-Id'] = listid

      mail_without_patch(headers, &block)
    end
  end
end

unless Mailer.included_modules.include?(RedmineMailFrom::MailerModelPatch)
  Mailer.send(:include, RedmineMailFrom::MailerModelPatch)
end
