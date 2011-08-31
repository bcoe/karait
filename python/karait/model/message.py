class Message(object):
    
    def __init__(self, dictionary={}):
        self._from_dictionary(dictionary)
        
    def _from_dictionary(self, dictionary):
        for key, value in dictionary.items():
            self.__dict__[key] = value
        
    def to_dictionary(self):
        return self.__dict__