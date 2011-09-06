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
        self._check_if_expired()
        
    def _from_dictionary(self, dictionary):
        for key, value in dictionary.items():
            if not key in self.BLACKLIST:
                self.__dict__[key] = value

    def _check_if_expired(self):
        meta = self._source.get('_meta', {})
        expire = meta.get('expire', -1.0)
        
        if expire <= -1.0:
            return
        
        if ( time.time() - meta.get('timestamp', 0.0) ) > expire:
            self._expired = True
            self.delete()
    
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