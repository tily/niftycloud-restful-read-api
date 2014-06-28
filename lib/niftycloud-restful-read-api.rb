require 'logger'
require 'openssl'
require 'base64'
require 'time'

require 'httparty'
require 'sinatra'
require 'json'
require 'NIFTY'
require 'aws-sdk'

NIFTY::LOG.level = Logger::DEBUG

# monkey patch
class NIFTY::Base
  def response_error?(response)
    false
  end
end

class NiftycloudRestfulReadApi < Sinatra::Base
  class NiftyCloud
    class Computing
      VERSION = '1.18'
  
      def initialize(options)
        @api = NIFTY::Cloud::Base.new(
          :access_key => options[:access_key_id],
          :secret_key => options[:secret_access_key],
          :server => "#{options[:region]}.cp.cloud.nifty.com",
          :path => '/api'
        )
      end

      def items(options)
        response = @api.send(:response_generator, 'Action' => options[:action])
        response[options[:key]].item.to_a rescue []
      end

      {
        :regions => {:action => 'DescribeRegions', :key => 'regionInfo'},
        :availability_zones => {:action => 'DescribeAvailabilityZones', :key => 'availabilityZoneInfo'},
        :volumes => {:action => 'DescribeVolumes', :key => 'volumeSet'}, 
        :key_pairs => {:action => 'DescribeKeyPairs', :key => 'keySet'},
        :images => {:action => 'DescribeImages', :key => 'imagesSet'},
        :security_groups => {:action => 'DescribeSecurityGroups', :key => 'securityGroupInfo'},
        :ssl_certificates => {:action => 'DescribeSSLCertificates', :key => 'certsSet'},
        :addresses => {:action => 'DescribeAddresses', :key => 'addressesSet'}
      }.each do |method, options|
        define_method method do
          items(:action => options[:action], :key => options[:key])
        end
      end

      def load_balancers
        response = @api.describe_load_balancers
        response.DescribeLoadBalancersResult.LoadBalancerDescriptions.member.to_a rescue []
      end
  
      def instances
        items = items(:action => 'DescribeInstances', :key => 'reservationSet')
        instances = items.map do |item|
          security_groups = item.groupSet.item.flatten.map {|item| item.groupId }
          instances = item.instancesSet.item.to_a
          instances.each do |instance|
            instance['securityGroups'] = security_groups
          end
          instances
        end
        instances.flatten
      end
    end

    class Rdb
      VERSION = '2013-05-15N2013-12-16'

      def initialize(options)
        @api = NIFTY::Cloud::Base.new(
          :access_key => options[:access_key_id],
          :secret_key => options[:secret_access_key],
          :server => "rdb.jp-#{options[:region]}.api.cloud.nifty.com",
          :path => '/'
        )
      end
  
      def db_instances
        response = @api.send(:response_generator, 'Action' => 'DescribeDBInstances')
        [response.DescribeDBInstancesResult.DBInstances.DBInstance].flatten rescue []
      end

      def db_security_groups
        response = @api.send(:response_generator, 'Action' => 'DescribeDBSecurityGroups')
        [response.DescribeDBSecurityGroupsResult.DBSecurityGroups.DBSecurityGroup].flatten rescue []
      end

      def db_parameter_groups
        response = @api.send(:response_generator, 'Action' => 'DescribeDBParameterGroups')
        [response.DescribeDBParameterGroupsResult.DBParameterGroups.DBParameterGroup].flatten rescue []
      end

      def db_snapshots
        response = @api.send(:response_generator, 'Action' => 'DescribeDBSnapshots')
        [response.DescribeDBSnapshotsResult.DBSnapshots.DBSnapshot].flatten rescue []
      end

      def db_engine_versions
        response = @api.send(:response_generator, 'Action' => 'DescribeDBEngineVersions')
        [response.DescribeDBEngineVersionsResult.DBEngineVersions.DBEngineVersion].flatten rescue []
      end

      # TODO: Engine
      #def orderable_db_instance_options
      #  response = @api.send(:response_generator, 'Action' => 'DescribeOrderableDBInstanceOptions')
      #  p response
      #  [response.DescribeOrderableDBInstanceOptionsResult.OrderableDBInstanceOptions.OrderableDBInstanceOption].flatten rescue []
      #end
    end

    class Mq
      VERSION = '2012-11-05N2013-12-16'

      def initialize(options)
        @api = NIFTY::Cloud::Base.new(
          :access_key => options[:access_key_id],
          :secret_key => options[:secret_access_key],
          :server => "mq.jp-#{options[:region]}.api.cloud.nifty.com",
          :path => '/'
        )
      end
  
      # TODO: GetQueueAttributes
      def queues
        response = @api.send(:response_generator, 'Action' => 'ListQueues')
        [response.ListQueuesResult.QueueUrl].flatten.map {|queue_url| {'QueueUrl' => queue_url} } rescue []
      end
    end
    
    class Dns
      include HTTParty
      $debug_output = true
      base_uri 'https://dns.api.cloud.nifty.com'

      VERSION = '2012-12-12N2013-12-16'

      def initialize(options)
        @access_key_id = options[:access_key_id]
        @secret_access_key = options[:secret_access_key]
      end
    
      def zones
        @date = Time.now.rfc2822.gsub(/(\-|\+)\d{4}$/, 'GMT')
        response = self.class.get("/#{Dns::VERSION}/hostedzone", :headers => headers)
        [response['ListHostedZonesResponse']['HostedZones']['HostedZone']].flatten rescue []
      end

      def headers
        {
          'x-nifty-authorization' => "NIFTY3-HTTPS NIFTYAccessKeyId=#{@access_key_id},ALgorithm=HmacSHA256,Signature=#{signature}", 
          'x-nifty-date' => @date
        }
      end

      def signature
        signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), @secret_access_key, @date)).strip
      end
    end

    class Storage
      include HTTParty
      $debug_output = true

      VERSION = '0'

      def initialize(options)
        @access_key_id = options[:access_key_id]
        @secret_access_key = options[:secret_access_key]
        if options[:region] == 'east-1'
          self.class.base_uri "https://ncss.nifty.com"
        else
          self.class.base_uri "https://#{options[:region]}-ncss.nifty.com"
        end
      end
    
      def buckets
        @date = Time.now.rfc2822.gsub(/(\-|\+)\d{4}$/, 'GMT')
        response = self.class.get("/", :headers => headers)
        [response['ListAllMyBucketsResult']['Buckets']['Bucket']].flatten rescue []
      end

      def headers
        {
          'authorization' => "NIFTY #{@access_key_id}:#{signature}", 
          'date' => @date,
          'content-type' => 'text/plain'
        }
      end

      def signature
        signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), @secret_access_key, string_to_sign)).strip
      end

      def string_to_sign
        str = []
        str << 'GET'
        str << ''
        str << 'text/plain'
        str << @date
        str << '/'
        str.join("\n")
      end
    end
  end
  
  helpers do
    SERVICE_CLASS = {
      :computing => NiftyCloud::Computing,
      :rdb       => NiftyCloud::Rdb,
      :mq        => NiftyCloud::Mq,
      :dns       => NiftyCloud::Dns,
      :storage   => NiftyCloud::Storage
    }

    def service(service)
      NIFTY::VERSION.gsub!(/^.+$/) { SERVICE_CLASS[service]::VERSION }
      SERVICE_CLASS[service].new(
        :region => @region,
        :access_key_id => @access_key_id,
        :secret_access_key => @secret_access_key
      )
    end
  end
  
  before do
    content_type 'text/plain'
    @region = params[:region] || 'east-1'
    @access_key_id = params[:access_key_id] || ENV['ACCESS_KEY_ID']
    @secret_access_key = params[:secret_access_key] || ENV['SECRET_ACCESS_KEY']
  end
  
  get '/:service/:resources' do
    service(params[:service].to_sym).send(params[:resources]).to_json
  end
end
