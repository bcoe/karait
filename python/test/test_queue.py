import unittest, time
from karait import Queue, Message
from pymongo import Connection, code

class TestQueue(unittest.TestCase):
    
    def setUp(self):
        Connection().karait_test.queue_test.drop()
        
    def test_queue_initializes_capped_collection_for_queue_if_collection_does_not_exist(self):
        queue = Queue(
            database='karait_test',
            queue='queue_test',
            average_message_size=8192,
            queue_size=4096
        )
        collection = Connection().karait_test.queue_test
        options = collection.options()
        self.assertEqual(1, options['capped'])
        self.assertEqual(4096, options['max'])
        self.assertEqual( (8192 * 4096) , options['size'])
        
    def test_queue_object_can_attach_to_a_collection_that_already_exists(self):
        collection = Connection().karait_test.queue_test
        collection.insert({
            'routing_key': 'foobar',
            'message': {
                'apple': 3,
                'banana': 5
            },
            'timestamp': 2523939,
            'expire': 20393
        })
        queue = Queue(
            database='karait_test',
            queue='queue_test'
        )
        self.assertEqual(1, collection.find({}).count())
        
    def test_writing_a_dictionary_to_the_queue_populates_it_within_mongodb(self):
        queue = Queue(
            database='karait_test',
            queue='queue_test'
        )
        queue.write({
            'apple': 5,
            'banana': 6,
            'inner_object': {
                'foo': 1,
                'bar': 2
            }
        })

        collection = Connection().karait_test.queue_test
        obj = collection.find_one({})
        self.assertEqual(6, obj['banana'])
        self.assertEqual(2, obj['inner_object']['bar'])
        self.assertTrue(obj['_meta']['expire'])
        self.assertTrue(obj['_meta']['timestamp'])
        
    def test_writing_a_message_to_the_queue_populates_it_within_mongodb(self):
        queue = Queue(
            database='karait_test',
            queue='queue_test'
        )
        
        message = Message()
        message.apple = 5
        message.banana = 6
        message.inner_object = {
            'foo': 1,
            'bar': 2
        }
        queue.write(message)

        collection = Connection().karait_test.queue_test
        obj = collection.find_one({})
        self.assertEqual(6, obj['banana'])
        self.assertEqual(2, obj['inner_object']['bar'])
        self.assertTrue(obj['_meta']['expire'])
        self.assertTrue(obj['_meta']['timestamp'])
        
    def test_reading_from_the_queue_returns_a_message_object(self):
        queue = Queue(
            database='karait_test',
            queue='queue_test'
        )
        
        write_message = Message()
        write_message.apple = 5
        write_message.banana = 6
        write_message.inner_object = {
            'foo': 1,
            'bar': 2
        }
        queue.write(write_message)
        
        read_message = queue.read()[0]
        self.assertEqual(5, read_message.apple)
        self.assertEqual(2, read_message.inner_object['bar'])
        self.assertEqual(3, len(read_message.to_dictionary().keys()))
        
    def test_messages_returned_in_fifo_order(self):
        queue = Queue(
            database='karait_test',
            queue='queue_test'
        )
        queue.write(Message({'foo': 1}))
        queue.write(Message({'foo': 2}))
        queue.write(Message({'foo': 3}))
        messages = queue.read()
        self.assertEqual(1, messages[0].foo)
        self.assertEqual(2, messages[1].foo)
        self.assertEqual(3, messages[2].foo)
    
    def test_routing_key_can_optionally_be_used_to_return_only_select_messages(self):
        queue = Queue(
            database='karait_test',
            queue='queue_test'
        )
        queue.write(Message({'foo': 1}), routing_key='foobar')
        queue.write(Message({'foo': 2}))
        messages = queue.read(routing_key='foobar')
        self.assertEqual(1, len(messages))
        self.assertEqual(1, messages[0].foo)
        
    def test_read_with_no_routing_key_only_returns_messages_with_no_routing_key(self):
        queue = Queue(
            database='karait_test',
            queue='queue_test'
        )
        queue.write(Message({'foo': 1}), routing_key='foobar')
        queue.write(Message({'foo': 2}))
        messages = queue.read()
        self.assertEqual(1, len(messages))
        self.assertEqual(2, messages[0].foo)
    
    def test_calling_delete_on_a_message_returned_removes_it_from_mongodb(self):
        collection = Connection().karait_test.queue_test
        queue = Queue(
            database='karait_test',
            queue='queue_test'
        )
        queue.write(Message({'foo': 1}))
        self.assertEqual(1, collection.find({}).count())
        queue.read()[0].delete()
        self.assertEqual(0, len(queue.read()))
    
    def test_message_with_expire_set_does_not_immediately_expire(self):
        queue = Queue(
            database='karait_test',
            queue='queue_test'
        )
        queue.write(Message({'foo': 1}), expire=0.1)
        self.assertEqual(1, len(queue.read()))
        self.assertEqual(1, len(queue.read()))
    
    def test_expired_messages_not_returned_by_read(self):
        queue = Queue(
            database='karait_test',
            queue='queue_test'
        )
        queue.write(Message({'foo': 1}), expire=0.1)
        time.sleep(0.2)
        self.assertEqual(0, len(queue.read()))
        self.assertEqual(0, len(queue.read()))
        
        # Make sure the meta._expired key is actually set.
        collection = Connection().karait_test.queue_test
        raw_message = collection.find_one({})
        self.assertEqual(True, raw_message['_meta']['expired'])
        
    def test_delete_messages_removes_whole_set_of_messages(self):
        queue = Queue(
            database='karait_test',
            queue='queue_test'
        )
        queue.write(Message({'foo': 1}))
        queue.write(Message({'foo': 2}))
        queue.write(Message({'foo': 3}))
        messages = queue.read()
        self.assertEqual(3, len(messages))
        queue.delete_messages(messages)
        messages = queue.read()
        self.assertEqual(0, len(messages))
        
    def test_setting_visibility_timeout_makes_a_message_unavailable_for_a_set_number_of_milliseconds(self):
       queue = Queue(
           database='karait_test',
           queue='queue_test'
       )
       queue.write(Message({'foo': 1}))
       queue.write(Message({'foo': 2}))
       queue.write(Message({'foo': 3}))
       messages = queue.read(visibility_timeout=0.4)
       self.assertEqual(3, len(messages))
       messages = queue.read()
       self.assertEqual(0, len(messages))
       time.sleep(0.5)
       messages = queue.read()
       self.assertEqual(3, len(messages))
    
    def test_a_message_with_a_unique_key_specified_can_only_be_inserted_once_for_a_given_key_value(self):
       queue = Queue(
           database='karait_test',
           queue='queue_test'
       )
       queue.write(Message({'foo': 'value1'}), unique_key='foo')
       queue.write(Message({'foo': 'value1'}), unique_key='foo')
       queue.write(Message({'foo': 'value2'}), unique_key='foo')
       messages = queue.read()
       self.assertEqual(len(messages), 2)