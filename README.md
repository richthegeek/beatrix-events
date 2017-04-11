# beatrix-events

System for emitting and reacting to events using [Beatrix](https://github.com/richthegeek/beatrix) / RabbitMQ

## Sample usage
```coffeescript
Manager = require 'beatrix-events'

Manager.connect {
  name: 'blah', # name of exchange, defaults to 'events'
  uri: 'amqp://guest:guest@localhost/' # would normally be passed based on environment settings
}

# listen for all types of people
Manager.on 'people.*', {
  persistent: true, # enqueue events of this type even when this consumer isnt alive
  filter: {age: {$gt: 20}} # only run the method for people over 20
}, (person, done) ->
  done null, person.typeArray[1] + ' was ' + person.age

setInterval (->
  Manager.emit 'people.bob', {age: Math.round(40 * Math.random())}
), 1000
```
