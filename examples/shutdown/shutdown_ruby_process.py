from karait import Message, Queue

print 'Terminating Ruby process.'

queue = Queue()
queue.write(
    {
        'action': 'shutdown_routed'
    },
    routing_key='ruby_process'
)