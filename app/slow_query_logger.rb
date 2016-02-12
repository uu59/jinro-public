class SlowQueryLogger < Arproxy::Base
  def initialize(slow_ms)
    @slow_ms = slow_ms
  end

  def execute(sql, name=nil)
    result = nil
    ms = Benchmark.ms { result = super(sql, name) }
    if ms >= @slow_ms
      stack = caller(1).grep_v(%r|/lib/ruby/|).join("\n")
      # TODO: machine friendlyなフォーマットに
      logger.info "Slow(#{ms.to_i}ms): #{sql}\n#{stack}"
    end
    result
  end
  
  private

  def logger
    Logger.new(log_file_path)
  end

  def log_file_path
    App.root.join("log/#{App.env}.slowsql.#{Time.now.strftime("%F")}.log")
  end
end
