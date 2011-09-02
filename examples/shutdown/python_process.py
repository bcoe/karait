from karait import Message, Queue

print('Starting Python process.')
queue = Queue()

while True:
  messages = queue.read()
  
  if messages and messages[0].action == 'shutdown_broadcast':
    print('Terminating due to broadcast shutdown message.')
    break