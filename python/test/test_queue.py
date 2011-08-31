import unittest
from karait import Queue
from pymongo import Connection

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
            'expiry': 20393
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
        self.assertTrue(obj['expiry'])
        self.assertTrue(obj['timestamp'])