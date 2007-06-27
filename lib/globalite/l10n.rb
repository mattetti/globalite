module Globalite 
  
  module L10n
    @@default_language = :en
    attr_reader :default_language

    @@default_country = :*
    mattr_reader :default_country

    @@reserved_keys = [ :limit ]
    mattr_reader :reserved_keys

    @@languages = []
    def languages
      @@languages
    end
    
    def default_language
      @@default_language
    end
    
    @@countries = []
    def countries
      @@countries
    end

    @@locales = {}
    def locales
      @@locales.keys
    end

    @@current_language = nil
    def current_language
      @@current_language || default_language
    end
    alias language current_language

    @@current_country = nil
    def current_country
      @@current_country || default_country
    end
    alias country current_country

    def current_locale
      "#{current_language}-#{current_country}".to_sym
    end
    alias locale current_locale
    
    # Set the current language ( ISO 639-1 language code in lowercase letters)
    # Usage:
    # Globalite.current_language = 'fr' or Globalite.current_language = :Fr
    # Will save the current language code if available, otherwise nada, switching back to the previous language
    #
    def current_language=(language)
      
      language = language.to_s.downcase.to_sym if language.class == Symbol
      language = language.downcase.to_sym if language.class == String && !language.empty?

      if @@languages.include?(language)
        @@current_language = language
        if !@@locales.include?("#{language}-#{@@current_country}".to_sym)
          @@current_country = :*
        end
      end
      
      Locale.update_session_locale
      localize_rails
      @@current_language
    end
    
    # Set the current country code (ISO 3166 country code in uppercase letters)
    # Usage:
    # Globalite.current_country = 'US' or Globalite.current_country = :fr
    # Will store the current country code if supported 
    # Will try to automatically find the language for your country
    # If the country isn't unknown to the system, the country will be set as :*
    #
    def current_country=(country)
      load_localization! if defined? RAILS_ENV && RAILS_ENV == 'development'
      country = country.to_s.upcase.to_sym if country.class == Symbol
      country = country.upcase.to_sym if country.class == String && !country.empty?

      if @@locales.include?("#{current_language}-#{country}".to_sym)
        @@current_country = country
      elsif locales.each {|locale| locale =~ /[a-z][a-z]-#{country.to_s}/ }
        locales.each do |key| 
          if key.to_s.include?(country.to_s)  
            @new_language = key.to_s.split('-')[0].downcase.to_sym
          end
        end
        if @new_language
          @@current_language = @new_language 
          @@current_country = country 
        end
      else  
        @@current_country = :*
      end
      Locale.update_session_locale
      @@current_country
    end
    
    def current_locale=(locale)
      Locale.set_code(locale)
    end

    @@localization_sources = []
    def add_localization_source(path)
      @@localization_sources << path
      load_localization!
    end
    
    def localization_sources
      @@localization_sources
    end

    # List localizations for the current locale
    def localizations
        if !locales.include?(Locale.code) 
          locales.each { |key| @t_locale = key if key.to_s.include?("#{@@current_language.to_s}") }
          @@locales[@t_locale] || {}
        else 
          @@locales[Locale.code] || {}
        end  
    end
    
    # Returns the translation for the key, a string can be passed to replaced a missing translation
    # TODO support interpolation of passed arguments
    def localize(key, string='__localization_missing__', args={})
      return if reserved_keys.include? key
      localized = localizations[key] || string
      localized = interpolate_string(localized.dup, args.dup) if localized.class == String
      localized
    end
    alias loc localize
    
    def localize_with_args(key, args={})
      localize(key, '_localization missing_', args)
    end
    alias l_with_args localize_with_args

    def add_reserved_key(*key)
      (@@reserved_keys += key.flatten).uniq!
    end
    alias :add_reserved_keys :add_reserved_key

    def reset_l10n_data
      @@languages = []
      @@countries = []
      @@locales = {}
    end

    # Loads ALL the UI localization in memory, I might want to refactor this later on. 
    # (can be hard on the memory if you load 25 languages with 900 strings in each)
    def load_localization!
      reset_l10n_data
      
      # Load the rails localization
      if rails_localization_files
        rails_localization_files.each do |file|
          lang = File.basename(file, '.*')[0,2].downcase.to_sym
          # if a country is defined
          if File.basename(file, '.*')[3,5]
            country = File.basename(file, '.*')[3,5].upcase.to_sym
            @@countries <<  country if ( country != :* && !@@countries.include?(country) )
            if locales.include?("#{lang}-#{country}".to_sym)
              @@locales["#{lang}-#{country}".to_sym].merge(YAML.load_file(file).symbolize_keys)
            else
              @@locales["#{lang}-#{country}".to_sym] = YAML.load_file(file).symbolize_keys
            end
            @@languages << lang unless @@languages.include? lang
          else
            @@languages << lang unless @@languages.include? lang 
            @f_locale = "#{lang}-*".to_sym
            @@locales[@f_locale] = @@locales[@f_locale].merge(YAML.load_file(file).symbolize_keys) if locales.include?(@f_locale)
            @@locales[@f_locale] = YAML.load_file(file).symbolize_keys unless locales.include?(@f_locale)
          end
        end
      end
      
      # Load the UI localization
      if ui_localization_files
        ui_localization_files.each do |file| 
          lang = File.basename(file, '.*')[0,2].downcase.to_sym
          if File.basename(file, '.*')[3,5]
            country = File.basename(file, '.*')[3,5].upcase.to_sym
          else
            country = '*'.to_sym
          end
          @@languages << lang unless @@languages.include? lang
          @@countries <<  country if ( country != :* && !@@countries.include?(country) )
          @file_locale = "#{lang}-#{country}".to_sym
          if locales.include?(@file_locale)
            @@locales[@file_locale] = @@locales[@file_locale].merge(YAML.load_file(file).symbolize_keys)
          else  
            @@locales[@file_locale] = YAML.load_file(file).symbolize_keys
          end
        end
      end
      localize_rails
      # Return the path of the localization files
       return "#{ui_localization_files} | #{rails_localization_files}".to_s
    end

    protected
    def ui_localization_files
      loc_files = Dir[File.join(RAILS_ROOT, 'lang/ui/', '*.{yml,yaml}')]
      unless @@localization_sources.empty?
        @@localization_sources.each do |path|
          loc_files += Dir[File.join(path, '*.{yml,yaml}')]
        end
      end
      loc_files
    end
    
    # Rails localization files, doesn't support locales, only 1 file per language
    def rails_localization_files
      loc_files = Dir[File.join( RAILS_ROOT, '/vendor/plugins/globalite/lang/rails/', '*.{yml,yaml}')]
    end

    def interpolate_string(string, args={})
      if args.length > 0
        args.each do |arg|
          string = string.gsub("{#{arg[0].to_s}}", arg[1])
        end
      end
      string
    end
    
  end
end