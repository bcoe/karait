import time
import pymongo
from karait.model.message import Message

class Queue(object):
    
    ALREADY_EXISTS_EXCEPTION_STRING = 'collection already exists'
    
    def __init__(
        self,
        host='localhost',
        port=27017,
        database='karait',
        queue='messages',
        average_message_size=8192,
        queue_size=4096
    ):
        self.host = host
        self.port = port
        self.database = database
        self.queue = queue
        self.average_message_size = average_message_size
        self.queue_size = queue_size
        self._create_mongo_connection()
        
    def _create_mongo_connection(self):
        self.connection = pymongo.Connection(
            self.host,
            self.port
        )
        self._create_capped_collection()
        
    def _create_capped_collection(self):
        try:
            pymongo.collection.Collection(
                self.connection[self.database],
                self.queue,
                size = (self.average_message_size * self.queue_size),
                capped = True,
                max = self.queue_size,
                create = True
            )
        except pymongo.errors.OperationFailure, operation_failure:
            if not self.ALREADY_EXISTS_EXCEPTION_STRING in str(operation_failure):
                raise operation_failure
    
    def write(self, message):
        if type(message) == dict:
            message_dict = message
        else:
            message_dict = message.to_dictionary()
            
        message_dict['_meta'] = {}
        message_dict['_meta']['timestamp'] = time.time()
        message_dict['_meta']['expiry'] = -1.0
                
        self.connection[self.database][self.queue].insert(message_dict)
    
    def read(self, routing_key=None):
        messages = []
        for raw_message in self.connection[self.database][self.queue].find():
            messages.append(
                Message(dictionary=raw_message, queue=self)
            )
        return messages