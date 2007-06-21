module ActionView
  
  # Modify DateHelper to use localization keys
  module Helpers
    
    #Modify DateHelper distance_of_time_in_words
    module DateHelper
      
      alias_method :old_distance_of_time_in_words, :distance_of_time_in_words
      def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
        from_time = from_time.to_time if from_time.respond_to?(:to_time)
        to_time = to_time.to_time if to_time.respond_to?(:to_time)
        distance_in_minutes = (((to_time - from_time).abs)/60).round
        distance_in_seconds = ((to_time - from_time).abs).round

        case distance_in_minutes
        when 0..1
          return (distance_in_minutes==0) ? :date_helper_less_than_a_minute.l :  :date_helper_one_minute.l unless include_seconds
          case distance_in_seconds
          when 0..5        then format( :date_helper_less_than_x_seconds.l , 5 )
          when 6..10       then format( :date_helper_less_than_x_seconds.l , 10 )
          when 11..20      then format( :date_helper_less_than_x_seconds.l , 20 )
          when 21..40      then :date_helper_half_a_minute.l 
          when 41..59      then :date_helper_less_than_a_minute.l 
          else                  :date_helper_one_minute.l 
          end

        when 2..44           then format(:date_helper_x_minutes.l, distance_in_minutes)
        when 45..89          then :date_helper_one_hour.l 
        when 90..1439        then format( :date_helper_x_hours.l , (distance_in_minutes.to_f / 60.0).round )
        when 1440..2879      then :date_helper_one_day.l 
        when 2880..43199     then format( :date_helper_x_days.l , (distance_in_minutes / 1440).round )
        when 43200..86399    then :date_helper_one_month.l 
        when 86400..525959   then format( :date_helper_x_months.l , (distance_in_minutes / 43200).round )
        when 525960..1051919 then :date_helper_one_year.l 
        else                      format( :date_helper_x_years.l , (distance_in_minutes / 525960).round )
        end
      end
    end

    module NumberHelper
      alias_method :orig_number_to_currency, :number_to_currency
      
      # modify number_to_currency to accept :order option
      def number_to_currency(number, options = {})
        # Blend default options with localized currency options
        #if :number_helper_unit.l != :missing_freaking_key.l
        options.reverse_merge!({:unit => :number_helper_unit.l, :separator => :number_helper_separator.l, :delimiter => :number_helper_delimiter.l, :order => :number_helper_order.l})
        # else
        #          options.reverse_merge!({:unit => "$", :separator => ".", :delimiter => ",", :order => [:unit, :number]})
        #        end
        #        options[:order] ||= [:unit, :number]
        options = options.stringify_keys
        
        precision, unit, separator, delimiter = options.delete("precision") { 2 }, options.delete("unit") { "$" }, options.delete("separator") { "." }, options.delete("delimiter") { "," }
        separator = "" unless precision > 0

        #add leading space before trailing unit
        unit = " " + unit if options["order"] == ['number', 'unit']
        output = ''
        begin
          options["order"].each do |param|
            case param
            when 'unit'
              output << unit
            when 'number'
              parts = number_with_precision(number, precision).split('.')
              output << number_with_delimiter(parts[0], delimiter) + separator + parts[1].to_s
            end
          end
        rescue
          output = number
        end
        output
      end
    end# module NumberHelper

    module DateHelper
      
      alias_method :orig_date_select, :date_select
      # Blend default options with localized :order option
      def date_select(object_name, method, options = {})
        options.reverse_merge!( :order => :date_helper_order.l )
        orig_date_select(object_name, method, options)
      end

      alias_method :orig_datetime_select, :datetime_select
      # Blend default options with localized :order option
      def datetime_select(object_name, method, options = {})
        options.reverse_merge!( :order => :date_helper_order.l )
        orig_datetime_select(object_name, method, options)
      end

      def select_month(date, options = {})
        val = date ? (date.kind_of?(Fixnum) ? date : date.month) : ''
        if options[:use_hidden]
          hidden_html(options[:field_name] || 'month', val, options)
        else
          month_options = []
          monthnames = :date_helper_month_names.l
          abbr_monthnames = :date_helper_abbr_month_names.l
          month_names = options[:use_month_names] || (options[:use_short_month] ? abbr_monthnames : monthnames)
          month_names.unshift(nil) if month_names.size < 13
          1.upto(12) do |month_number|
            month_name = if options[:use_month_numbers]
              month_number
            elsif options[:add_month_numbers]
              month_number.to_s + ' - ' + month_names[month_number]
            else
              month_names[month_number]
            end

            month_options << ((val == month_number) ?
              %(<option value="#{month_number}" selected="selected">#{month_name}</option>\n) :
              %(<option value="#{month_number}">#{month_name}</option>\n)
            )
          end
          select_html(options[:field_name] || 'month', month_options, options)
        end
      end
      
    end #module DateHelper


    module FormOptionsHelper
      
      def country_options_for_select(selected = nil, priority_countries = nil)
        country_options = ""

        if priority_countries
          country_options += options_for_select(priority_countries, selected)
          country_options += "<option value=\"\">-------------</option>\n"
        end

        if priority_countries && priority_countries.include?(selected)
          country_options += options_for_select(:countries_list.l - priority_countries, selected)
        else
          country_options += options_for_select(:countries_list.l, selected)
        end

        return country_options
      end
      
    end #module FormOptionsHelper
    
  end #module Helpers
end #module ActionView
