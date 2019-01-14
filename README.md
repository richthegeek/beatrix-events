# beatrix-events

System for emitting and reacting to events using [Beatrix](https://github.com/richthegeek/beatrix) / RabbitMQ

Events are optionally filtered using [Sift](https://github.com/crcn/sift.js)

## Sample usage
```javascript
const Manager = require('beatrix-events');

Manager.connect({
  name: 'blah', // name of this application, for namespacing queues
  uri: 'amqp://guest:guest@localhost/' // would normally be passed based on environment settings
});

// listen for all types of people
Manager.on('colony.people', {
  persistent: true, // enqueue events of this type even when this consumer isnt alive
  filter: {age: {$gt: 30}} // only run the method for people over 20
}, async (person) => {
  if (person.name > 'Logan') {
    throw new Error('Run, Logan, Run')
  }
  return person.name + ' was eliminated for the greater good';
})

setInterval(() => {
  Manager.emit('colony.people', generateRandomPerson());
}, 1000);
```
