module ET

  class Logger

    @@instance = Logger.new

    def configure(options)
      @@path = options[:path]
      @@log_level = options[:log_level] || 0

      # create directory if does not exist
      FileUtils.mkdir_p @@path unless (File::exist? @@path)
    end

    def self.instance
      return @@instance
    end

    def save_to_file log_level, content, options
      prefix = options[:prefix] + "-" || ''

      if log_level >= @@log_level
        filename = @@path + prefix + Time.now.strftime("%Y%m%d").to_s + "_" + (rand * 1000).to_i.to_s
        while File::exist? filename do
          filename = @@path + prefix + Time.now.strftime("%Y%m%d").to_s + "_" + (rand * 1000).to_i.to_s
        end
        File.open(filename, 'w') do |f|
          f.write content
        end
      end
    end

  end

end