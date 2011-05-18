module MCollective
  module Agent
    class Deploy < RPC::Agent
      metadata :name        => "Deploy",
               :description => "Deployment agent",
               :author      => "Anonymous",
               :version     => "0.1",
               :license     => "private",
               :url         => "http://cn.com",
               :timeout     => 600

      action "war" do
        validate :source, String
        run("wget -O /tmp/war #{request[:source]}")
        run("service tomcat6 stop")
        run("rm -r /var/lib/tomcat6/webapps/*")
        run("mv /tmp/war /var/lib/tomcat6/webapps/companynews.war")
        run("service tomcat6 start")
      end
    end
  end
end
