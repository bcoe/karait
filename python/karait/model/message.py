import time

class Message(object):
    
    BLACKLIST = [
        '_meta',
        '_id',
        '_source',
        '_expired',
        '_queue_collection'
    ]
    
    def __init__(self, dictionary={}, queue_collection=None):
        self._queue_collection = queue_collection
        self._expired = False
        self._source = dictionary
        self._from_dictionary(dictionary)
        
    def _from_dictionary(self, dictionary):
        for key, value in dictionary.items():
            if not key in self.BLACKLIST:
                self.__dict__[key] = value
    
    def to_dictionary(self):
        dictionary = {}
        dictionary.update(self.__dict__)
        for key in self.BLACKLIST:
            if dictionary.has_key(key):
                del dictionary[key]
        return dictionary
    
    def delete(self):
        self._queue_collection.update(
            {
                '_id': self._source['_id']
            },
            {
                '$set': {
                    '_meta.expired': True
                }
            }
        )
        
    def is_expired(self):
        return self._expired