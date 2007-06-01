require File.dirname(__FILE__) + '/helpers/spec_helper'

describe "After loading languages, Globalite" do
  before(:all) do
    Globalite.add_localization_source(RAILS_ROOT + '/vendor/plugins/globalite/spec/lang/ui/')
    Globalite.load_localization!
  end
  
  before(:each) do
    Locale.set_code :"en-*"
  end

  it 'should have loaded en-US spec localization' do
    Globalite.locales.should include(:"en-US")
  end
  
  it 'should have a list of unique languages' do
    Globalite.languages.should be_an_instance_of(Array)
    Globalite.languages.should == Globalite.languages.uniq
  end
  
  it 'should have a list of unique countries' do
    Globalite.countries.should be_an_instance_of(Array)
    Globalite.countries.should == Globalite.countries.uniq
  end
  
  it 'should have a list of unique locales' do
    Globalite.locales.should be_an_instance_of(Array)
    Globalite.locales.should == Globalite.locales.uniq
  end
  
  it "should have at least some English localization" do
    Globalite.languages.should include(:en)
  end

  it "should know if it is using the default language" do
    Globalite.current_language.should == Globalite.default_language
  end

  it "should be able to switch between existing languages" do
    Globalite.current_language = :fr
    string = "Welcome, dude!"
    Globalite.localize(:welcome_friend).should_not == string
    Globalite.localize(:welcome_friend).should == "Bienvenue l'ami!"
    
    Globalite.current_language = :es
    Globalite.localize(:welcome_friend).should_not == string

    Globalite.current_language = nil
    Globalite.localize(:welcome_friend).should_not == string

    Globalite.current_language = :en
    Globalite.current_country = :US
    Globalite.locales.should include(:"en-US")
    Locale.code.should == :"en-US"
    Globalite.localize(:welcome_friend).should == string
  end

  it "should be able to switch languages using strings" do
    Globalite.current_language = 'es'
    Globalite.current_language.should == :es
  end

  it "should be able to switch to the default language at any time" do
    Globalite.current_language = :fr
    Globalite.current_language.should_not ==(Globalite.default_language)

    Globalite.current_language = :en
    Globalite.current_language.should ==(Globalite.default_language)
  end

  it "should be able to set the current locale" do
    Globalite.current_locale = 'en-US'
    Globalite.current_locale.should == 'en-US'.to_sym
  end

  it "should not be able to change the current country if there's no locale for it" do
    Globalite.current_locale.should == "en-*".to_sym
    Globalite.current_country = :FR
    Globalite.current_locale.should == "en-*".to_sym
  end  

  it "should let you assign a valid locale" do
    Globalite.current_locale = :"fr-*"
    Globalite.current_locale.should == :"fr-*"
  end

  it "should auto assign a language if you try to set a country defined in an available locale" do
    Globalite.current_locale = :"fr-*"
    Globalite.current_country = :US
    Globalite.current_locale.should == "en-US".to_sym    
  end

  it "should auto assign a wild card if a country isn't assigned" do
    Globalite.current_language = :fr
    Globalite.current_locale.should == "fr-*".to_sym
  end

  it "should find translations for a locale without country even though there's no generic translation for the language" do  
    Globalite.current_locale = :"fr-*"
    Globalite.current_language = :en
    Globalite.current_language.should == :en 
    Globalite.localizations.should_not be {}
  end

  it "should return an array of the languages it loaded" do
    Globalite.load_localization!
    languages = Globalite.languages
    languages.should be_an_instance_of(Array)
    languages.should include(:en)
    languages.should include(:fr)
    Globalite.locales.should include(:"en-US")
  end

  it "should return an array of locales it loaded" do
    locales = Globalite.locales
    locales.should be_an_instance_of(Array)
    locales.should include(:"en-US")
    locales.should include(:"fr-*")
  end

  it "should be able to accept new, unique reserved keys" do
    key = :something_evil
    Globalite.add_reserved_key key
    Globalite.reserved_keys.should include(key)
    Globalite.reserved_keys.size.should == 2
    Globalite.add_reserved_key key
    Globalite.add_reserved_key key
    Globalite.reserved_keys.size.should == 2
  end
  
  it "shouldn't be able to set a unsupported locale" do
    Locale.set_code :"te-st"
    Locale.code.should == :"en-*"
    Locale.set_code 'test'
    Locale.code.should == :"en-*"
  end
   
end

describe "When a non-existent language is set" do
  before(:each) do
    Globalite.current_language = :klingon
  end

  it "the previous language should be used" do
    Globalite.current_language.should == Globalite.default_language
    Globalite.current_language = :fr
    # testing alias
    Globalite.language.should == :fr
    Globalite.current_language = :klingon
    Globalite.current_language.should == :fr
  end

end

describe "a localization key (in general)" do

  before(:each) do
    Globalite.current_locale = "en-US".to_sym
  end

  it "should return the proper localization it the key is localized" do
    :welcome_friend.localize.should == "Welcome, dude!"
    :welcome_friend.l.should == "Welcome, dude!"
    Globalite.current_language = :fr
    :welcome_friend.l.should == "Bienvenue l'ami!"
  end

  it "should return an optional string if the localization is missing" do
    :unknown_key.l("this is my replacement string").should == "this is my replacement string"
  end

  it "should return an error missing if the localization is missing and no option string was given" do
    :unknown_key.l.should == "__localization_missing__"
  end

  it "should return nil if a reserved key is used" do
    :limit.l.should be(nil)
  end

  it "should be able to localized a key with one or many passed arguments" do
    Globalite.current_language = :fr
    :welcome_user.l_with_args({:user => :user.l}).should == "Cher utilisateur, Bienvenue!"
    :many_args_test.l_with_args({:name => 'Matt', :what => 'déchire', :other => 'Serieusement'}).should == 'Serieusement, Matt vraiment déchire comme une bete ;)'
  end
  
end

describe "an alternative location with localization files" do
  before(:all) do
    Globalite.add_localization_source(File.dirname(__FILE__) + '/lang/rails')
  end
  
  it "could be added to the localization source path" do
    Globalite.load_localization!.should include("/spec/lang/rails/zz.yml")
  end
  
  it "should have been loaded properly" do
    Globalite.languages.should include(:zz)
    Globalite.locales.should include(:"zz-*")
  end
end