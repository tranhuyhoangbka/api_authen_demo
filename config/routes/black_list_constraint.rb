class BlackListConstraint
  def initialize
    @ips = ::BlackList.retrieve_ips
  end

  def matches?(request)
    @ips.include?(request.remote_ip)
  end
end
