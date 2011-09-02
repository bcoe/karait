import simplejson as json
from karait import Message, Queue

print 'Starting python reader.'

queue = Queue()
count = 0

while True:
    messages = queue.read()
    for message in messages:
        count += 1
        if count % 250 == 0:
            print("Message Read: \n%s" % json.dumps(message.to_dictionary(), indent=2))
        message.delete()
