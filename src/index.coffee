Beatrix = require 'beatrix'
Sift = require 'sift'
_ = require 'lodash'
uuid = require 'uuid'
Promise = require 'bluebird'

class Manager

  name: null
  ready: null
  connection: null

  connect: (options, cb) ->
    @name = options.name
    @ready = new Promise (resolve, reject) =>
      @connection = Beatrix {
        connection: {
          uri: options.uri
        },
        exchange: _.defaults {}, options.exchange, {
          name: 'events',
          autoDelete: false,
          durable: true,
          type: 'topic'
        }
      }, (err, res) ->
        if err
          reject err
        else
          resolve res

  filter: (filter, message) ->
    if 'function' is typeof filter
      return filter message

    if 'object' is typeof filter
      return Sift(filter)(message)

    return true

  # runs the provided `method` for all messages
  # matching the `event` passed
  # supported options:
  #  - name: queue name for logging, defaults to `event`
  #  - type: queue name in rabbit, defaults to `event`
  #  - routingKey: routing key in rabbit, defaults to `event`
  #  - persistent: boolean, should the queue still exist in between app lifetimes? default: true
  #  - autoDelete: boolean, should the queue delete when no consumers exist, based on `persistent`
  #  - durable: boolean, should the queue survive a rabbitmq reboot, based on `persistent`
  #  - filter: siftQuery or function that must return true for the event to be passed to the cb
  on: (event, options, method, cb) ->
    @ready.then =>
      options = _.defaults {}, options, {
        name: @name + '.' + event,
        type: @name + '.' + event,
        routingKey: event,
        autoDelete: options.persistent is false,
        durable: options.persistent isnt false,
        context: @
      }

      options.process = (message, cb) =>
        message.body.type ?= message.fields.routingKey
        message.body.typeArray ?= message.fields.routingKey.split('.')
        unless @filter options.filter, message.body
          return cb null, 'Filtered'

        method message.body, cb

      @connection.createQueue event, options, cb

  # publishes an event to the queue
  emit: (event, body, options, cb) ->
    options = _.defaults {}, options, {routingKey: event}
    @ready.then =>
      @connection.publish event, body, options, cb

module.exports = new Manager()