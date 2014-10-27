require "split/helper"
require "split"

module Split
  module Analytics
    def tracking_code(options={})
      # needs more options: http://code.google.com/apis/analytics/docs/gaJS/gaJSApi.html
      account = options.delete(:account)
      tracker_url = options.delete(:tracker_url)
      ssl_tracker_url = options.delete(:ssl_tracker_url)
      tracker_methods = options.delete(:tracker_methods)

      tracker_url = 'http://' + (tracker_url || 'www.google-analytics.com/ga.js')
      ssl_tracker_url = 'https://' + (ssl_tracker_url || 'ssl.google-analytics.com/ga.js')

      code = <<-EOF
        <script type="text/javascript">
          var _gaq = _gaq || [];
          _gaq.push(['_setAccount', '#{account}']);
          #{insert_tracker_methods(tracker_methods)}
          #{custom_variables}
          _gaq.push(['_trackPageview']);
          (function() {
            var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
            ga.src = ('https:' == document.location.protocol ? '#{ssl_tracker_url}' : '#{tracker_url}');
            var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
          })();
        </script>
      EOF
      code = raw(code)if defined?(raw)
      code
    end
    
    def universal_tracking_code(options={})
      # needs more options: http://code.google.com/apis/analytics/docs/gaJS/gaJSApi.html
      account = options.delete(:account)
      domain_url = options.delete(:domain_url)
      dimension = options.delete(:dimension)

      code = <<-EOF
        
        <!-- Google Analytics -->
        <script>
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
        m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

        ga('create', '#{account}', {cookieDomain: '#{domain_url}'}); 
        ga('send', 'pageview');
        #{universal_custom_variables(dimension)}
        </script>
        <!-- End Google Analytics -->
                 
      EOF
      code = raw(code)if defined?(raw)
      code
    end    

    def custom_variables
      return nil if session[:split].nil?
      arr = []
      session[:split].each_with_index do |h,i|
        arr << "_gaq.push(['_setCustomVar', #{i+1}, '#{h[0]}', '#{h[1]}', 1]);"
      end
      arr.reverse[0..4].reverse.join("\n")
    end

    def universal_custom_variables(dimension)
      # ga('set', 'dimension1', 'Paid');
      return nil if session[:split].nil?
      arr = []
      arr << "ga('set', '#{dimension}', "
      session[:split].each_with_index do |h,i|
        arr << "'#{h[0].split(":")[0]}-#{test_version(h[0].split(":")[1])}-#{complete(h[0],h[1])}-#{alt_percent(h[0],h[1])}' "
      end
      arr << ");"
      arr.reverse[0..4].reverse.join("\n")
    end
    
    private

      def insert_tracker_methods(tracker_methods)
        return nil if tracker_methods.nil?
        arr = []
        tracker_methods.each do |k,v|
          if v.class == String && v.empty?
            # No argument tracker method
            arr << "_gaq.push(['" + "_" + "#{k}']);"
          else
            case v
            when String
              # String argument tracker method
              arr << "_gaq.push(['" + "_" + "#{k}', '#{v}']);"
            when TrueClass
              # Boolean argument tracker method
              arr << "_gaq.push(['" + "_" + "#{k}', #{v}]);"
            when FalseClass
              # Boolean argument tracker method
              arr << "_gaq.push(['" + "_" + "#{k}', #{v}]);"
            when Array
              # Array argument tracker method
              values = v.map { |value| "'#{value}'" }.join(', ')
              arr << "_gaq.push(['" + "_" + "#{k}', #{values}]);"
            end
          end
        end
        arr.join("\n")
      end

      def insert_universal_tracker_methods(universal_tracker_methods)
        return nil if tracker_methods.nil?
        arr = []
        tracker_methods.each do |k,v|
          if v.class == String && v.empty?
            # No argument tracker method
            arr << "_gaq.push(['" + "_" + "#{k}']);"
          else
            case v
            when String
              # String argument tracker method
              arr << "_gaq.push(['" + "_" + "#{k}', '#{v}']);"
            when TrueClass
              # Boolean argument tracker method
              arr << "_gaq.push(['" + "_" + "#{k}', #{v}]);"
            when FalseClass
              # Boolean argument tracker method
              arr << "_gaq.push(['" + "_" + "#{k}', #{v}]);"
            when Array
              # Array argument tracker method
              values = v.map { |value| "'#{value}'" }.join(', ')
              arr << "_gaq.push(['" + "_" + "#{k}', #{values}]);"
            end
          end
        end
        arr.join("\n")
      end     
      
      def alt_percent(name,alt)
        if Split.configuration.experiments[name.split(":")[0]]
          sce = Split.configuration.experiments[name.split(":")[0]][:alternatives]
          sce.each do |e|
            if e[:name] == alt
             return e[:percent] || 50
            end 
          end
        end
        50
      end 
      
      def test_version(ver)
        unless ver.nil?
          if /\A[-+]?\d+\z/ === ver.split(":")[0]
            "#{ver.split(":")[0]}"
          else
            "0"
          end
        else
          "0"
        end  
      end
      
      def complete(name,alt)
        if name.include?"finished"
          "finished"
        else
          alt           
        end  
      end
  end  
end

module Split::Helper
  include Split::Analytics
end

if defined?(Rails)
  class ActionController::Base
    ActionController::Base.send :include, Split::Analytics
    ActionController::Base.helper Split::Analytics
  end
end