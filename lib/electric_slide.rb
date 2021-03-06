# encoding: utf-8
require 'celluloid'
require 'singleton'
%w(
  call_queue
  plugin
).each { |f| require "electric_slide/#{f}" }

class ElectricSlide
  include Singleton

  def initialize
    @mutex = Mutex.new
    @queues = {}
  end

  def create(name, queue_class = nil, *args)
    if @queues.key?(name)
      fail "Queue with name #{name} already exists!"
    else
      queue_class ||= CallQueue
      @queues[name] = queue_class.work *args
    end
  end

  def get_queue(name)
    fail "Queue #{name} not found!" unless @queues.key?(name)
    queue = @queues[name]
    if queue.respond_to? :actors
      # In case we have a Celluloid supervision group, get the current actor
      queue.actors.first
    else
      queue
    end
  end

  def shutdown_queue(name)
    queue = get_queue name
    queue.terminate
    @queues.delete name
  end

  def self.method_missing(method, *args, &block)
    @@mutex ||= Mutex.new
    @@mutex.synchronize do
      instance.send method, *args, &block
    end
  end
end
