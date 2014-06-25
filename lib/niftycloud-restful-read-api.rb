require 'sinatra'
require 'json'
require 'NIFTY'

class NiftyCloudRestfulReadApi < Sinatra::Base
  class NiftyCloud
    class Computing
  
      def initialize(options)
        @api = NIFTY::Cloud::Base.new(
          :access_key => options[:access_key_id],
          :secret_key => options[:secret_access_key],
          :endpoint => "{options[:region]}.cp.cloud.nifty.com",
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
        []
      end
  
      def addresses
        response = @api.send(:response_generator, 'Action' => 'DescribeAddresses')
        response.addressesSet.item.to_a rescue []
      end
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
end
