const Beatrix = require('beatrix');
const Sift = require('sift').default;
const _ = require('lodash');

class BeatrixEvents {

  connect (options) {
    this.name = options.name;
    this.connection = Beatrix({
      name: options.name,
      uri: options.uri,
      exchange: {
        name: 'events',
        autoDelete: false,
        durable: true,
        type: 'topic'
      },
      responseQueue: false
    });
  }

  filter (filter, message) {
    if (_.isFunction(filter)) {
      return filter(message);
    }

    if (_.isObject(filter)) {
      return Sift(filter)(message)
    }

    return true
  }

  // runs the provided `method` for all messages
  // matching the `event` passed
  // supported options:
  //  - name: queue name for logging, defaults to `event`
  //  - type: queue name in rabbit, defaults to `event`
  //  - routingKey: routing key in rabbit, defaults to `event`
  //  - persistent: boolean, should the queue still exist in between app lifetimes? default: true
  //  - autoDelete: boolean, should the queue delete when no consumers exist, based on `persistent`
  //  - durable: boolean, should the queue survive a rabbitmq reboot, based on `persistent`
  //  - filter: siftQuery or function that must return true for the event to be passed to the cb
  on (event, options, method) {
    options = _.defaults({}, options, {
      name: event,
      type: event,
      routingKey: event,
      autoDelete: options.persistent === false,
      durable: options.persistent !== false,
      context: this
    });

    options.process = this.process.bind(this, options, method)

    this.connection.createQueue(options.name, options)
  }

  process (options, method, message) {
    let body = _.defaults(message.body, {
      type: message.fields.routingKey,
      typeArray: message.fields.routingKey.split('.')
    });

    if (!this.filter(options.filter, body)) {
      return message.resolve('Filtered');
    }

    return method(message.body).then((res) => {
      message.resolve(res);
    }, (err) => {
      message.retry(true);
      message.reject(err);
    });
  }

  // publishes an event to the queue
  emit (event, body) {
    return this.connection.publish(event, body, {routingKey: event});
  }
}

module.exports = new BeatrixEvents()
