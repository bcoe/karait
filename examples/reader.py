import simplejson as json
from karait import Message, Queue

print 'Starting python reader.'

queue = Queue()
count = 0

while True:
    messages = queue.read(messages_read = 15)
    for message in messages:
        count += 1
        if count % 250 == 0:
            print("Message Read: \n%s" % json.dumps(message.to_dictionary(), indent=2))
    queue.delete_messages(messages)