import time
from karait import Message, Queue

print 'Starting python writer.'

messages_written = 0
start = time.time()
queue = Queue()

while True:
    queue.write({
        'messages_written': messages_written,
        'sender': 'writer.py',
        'started_running': start,
        'messages_written_per_second': (messages_written / (time.time() - start))
    }, routing_key='for_reader')
    messages_written += 1
    time.sleep(0.5)