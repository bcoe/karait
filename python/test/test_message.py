import unittest
from karait import Message
from pymongo import Connection

class TestMessage(unittest.TestCase):
    
    def setUp(self):
        Connection().karait_test.queue_test.drop()        

    def test_to_dictionary_returns_instance_variables_as_dictionary(self):
        message = Message()
        message.banana = 5
        message.apple = 7
        message.inner_dictionary = {
            'foo': 2,
            'bar': 4
        }
        dictionary = message.to_dictionary()
        self.assertEqual(7, dictionary['apple'])
        self.assertEqual(4, dictionary['inner_dictionary']['bar'])
        self.assertEqual(3, len(dictionary.keys()))
        
    def test_initializing_with_dictionary_adds_instance_variables_from_a_dictionary(self):
        dictionary = {
            'apple': 7,
            'banana': 5,
            'inner_dictionary': {
                'foo': 2,
                'bar': 4
            }
        }
        message = Message(dictionary)
        self.assertEqual(7, message.apple)
        self.assertEqual(2, message.inner_dictionary['foo'])
    
    def test_blacklisted_keys_not_copied_onto_message_object(self):
        dictionary = {
            '_id': 'foobar',
            '_meta': {
                'foo': 2
            }
        }
        message = Message(dictionary)
        self.assertFalse(message.__dict__.get('_id', False))
        self.assertFalse(message.__dict__.get('_meta', False))
        
    def test_calling_delete_removes_the_message_from_mongodb(self):
        collection = Connection().karait_test.queue_test
        collection.insert({
            'routing_key': 'foobar',
            'apple': 3,
            'banana': 5,
            '_meta': {
                'timestamp': 2523939,
                'expire': 20393,
                'expired': False
            }
        })
        raw_message = collection.find_one({'_meta.expired': False})
        self.assertEqual(3, raw_message['apple'])
        message = Message(raw_message, queue_collection=collection)
        message.delete()
        self.assertEqual(0, collection.find({'_meta.expired': False}).count())
        
    def test_expired_set_to_true_if_message_older_than_expire_time(self):
        dictionary = {
            'routing_key': 'foobar',
            'apple': 3,
            'banana': 5,
            '_meta': {
                'timestamp': 0,
                'expire': 10,
                'expired': False
            }
        }
        
        message = Message(dictionary)
        self.assertEqual(True, message.is_expired())
        
    def test_expired_not_set_to_true_if_expire_equals_minus_one(self):
        dictionary = {
            'routing_key': 'foobar',
            'apple': 3,
            'banana': 5,
            '_meta': {
                'timestamp': 0,
                'expire': -1.0,
                'expired': False
            }
        }
        
        message = Message(dictionary)
        self.assertEqual(False, message.is_expired())