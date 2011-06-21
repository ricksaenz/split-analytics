require "split/helper"

module Split
  module Analytics
    def tracking_code(options={})
      # needs more options: http://code.google.com/apis/analytics/docs/gaJS/gaJSApi.html
      account = options.delete(:account)

      <<-EOF
        <script type="text/javascript">
          var _gaq = _gaq || [];
          _gaq.push(['_setAccount', '#{account}']);
          #{custom_variables}
          _gaq.push(['_trackPageview']);

          (function() {
            var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
            ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
            var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
          })();
        </script>
      EOF
    end

    def custom_variables
      return nil if session[:split].nil?
      arr = []
      session[:split].each_with_index do |h,i|
        arr << "_gaq.push(['_setCustomVar', #{i+1}, '#{h[0]}', '#{h[1]}', 1]);"
      end
      arr[-5..-1].join("\n")
    end
  end
end

module Split::Helper
  include Split::Analytics
end

# mix Spilt::Analytics into Split::Helpers
