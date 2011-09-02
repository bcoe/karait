from karait import Message, Queue

print 'Terminating all processes.'

queue = Queue()
queue.write(
    {
        'action': 'shutdown_broadcast'
    },
    expire=10
)