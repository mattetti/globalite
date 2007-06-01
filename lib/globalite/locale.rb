class Locale
  attr_reader :language, :country, :code

  #
  def self.language
    Globalite.language
  end

  #
  def self.country
    Globalite.country
  end

  #
  def self.code
    ActionController::Base.session_options[:locale] ||= "#{Globalite.language}-#{Globalite.country}".to_sym
  end
  
  #
  def self.set_code(locale= code)
    if locale.to_s.split('-') && locale.to_s.length.between?(4,5) && Globalite.locales.include?(locale.to_sym) 
      Globalite.current_language = locale.to_s.split('-')[0].downcase.to_sym if locale.to_s.split('-')[0]
      Globalite.current_country = locale.to_s.split('-')[1].upcase.to_sym if locale.to_s.split('-')[1]
      set_session_locale("#{Globalite.language}-#{Globalite.country}")
    end
  end
  
  def self.update_session_locale
    set_session_locale
  end

  private
  #
  def self.set_session_locale(locale= Globalite.locale)
    ActionController::Base.session_options[:locale] = Globalite.locale.to_sym
  end

end
