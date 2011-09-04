import time
import json
from karait import Queue
print("Starting python reader.")

messages_read = 0.0
start_time = time.time()

queue = Queue()
while True:
  messages = queue.read(routing_key='for_reader', messages_read=15)
  for message in messages:
    messages_read += 1.0
        
    message.messages_read = messages_read
    message.messages_read_per_second = messages_read / (time.time() - start_time)
    
    if (messages_read % 250) == 0.0:
      print("Message Read: \n%s" % json.dumps(message.to_dictionary()))

  queue.delete_messages(messages)
