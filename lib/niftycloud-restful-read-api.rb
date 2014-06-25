require 'logger'
require 'sinatra'
require 'json'
require 'NIFTY'

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
  
      def initialize(options)
        @api = NIFTY::Cloud::Base.new(
          :access_key => options[:access_key_id],
          :secret_key => options[:secret_access_key],
          :server => "{options[:region]}.cp.cloud.nifty.com",
          :path => '/api'
        )
      end
  
      def regions
        response = @api.send(:response_generator, 'Action' => 'DescribeRegions')
        response.regionInfo.item.to_a rescue []
      end
      
      def instances
        response = @api.describe_instances
  
        return [] if response.reservationSet.nil?
  
        items = response.reservationSet.item
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
      
      def volumes
        response = @api.describe_volumes
        response.volumeSet.item.to_a rescue []
      end
      
      def key_pairs
        response = @api.describe_key_pairs
        response.keySet.item.to_a rescue []
      end
      
      def images
        response = @api.describe_images
        response.imagesSet.item.to_a rescue []
      end
      
      def load_balancers
        response = @api.describe_load_balancers
        response.DescribeLoadBalancersResult.LoadBalancerDescriptions.member.to_a rescue []
      end
      
      def security_groups
        response = @api.describe_security_groups
        response.securityGroupInfo.item.to_a rescue []
      end
      
      def ssl_certificates
        response = @api.describe_ssl_certificates
        response.certsSet.item.to_a rescue []
      end
  
      def addresses
        response = @api.send(:response_generator, 'Action' => 'DescribeAddresses')
        response.addressesSet.item.to_a rescue []
      end
    end

    class Rdb
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
        [response.DescribeDBInstancesResult.DBInstances.DBInstance.to_a].flatten rescue []
      end

      def db_security_groups
        response = @api.send(:response_generator, 'Action' => 'DescribeDBSecurityGroups')
        [response.DescribeDBSecurityGroupsResult.DBSecurityGroups.DBSecurityGroup.to_a].flatten rescue []
      end

      def db_parameter_groups
        response = @api.send(:response_generator, 'Action' => 'DescribeDBParameterGroups')
        [response.DescribeDBParameterGroupsResult.DBParameterGroups.DBParameterGroup.to_a].flatten rescue []
      end

      def db_snapshots
        response = @api.send(:response_generator, 'Action' => 'DescribeDBSnapshots')
        p response
        [response.DescribeDBSnapshotsResult.DBSnapshots.DBSnapshot.to_a].flatten rescue []
      end

      def db_engine_versions
        response = @api.send(:response_generator, 'Action' => 'DescribeDBEngineVersions')
        [response.DescribeDBEngineVersionsResult.DBEngineVersions.DBEngineVersion.to_a].flatten rescue []
      end

      # TODO: Engine
      #def orderable_db_instance_options
      #  response = @api.send(:response_generator, 'Action' => 'DescribeOrderableDBInstanceOptions')
      #  p response
      #  [response.DescribeOrderableDBInstanceOptionsResult.OrderableDBInstanceOptions.OrderableDBInstanceOption.to_a].flatten rescue []
      #end
    end
  end
  
  helpers do
    def compute
      @compute ||= NiftyCloud::Computing.new(
        :region => @region,
        :access_key_id => @access_key_id,
        :secret_access_key => @secret_access_key
      )
    end

    def rdb
      @rdb ||= NiftyCloud::Rdb.new(
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
  
  post '/computing/:resources' do
    compute.send(params[:resources]).to_json
  end

  post '/rdb/:resources' do
    NIFTY::VERSION = '2013-05-15N2013-12-16'
    rdb.send(params[:resources]).to_json
  end
end
